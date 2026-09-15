// Vercel serverless function: creates a Stripe PaymentIntent for a crowd
// member's tip, after re-verifying the gig session and nightly request cap
// server-side (never trust client-asserted state for a real charge).
//
// No auth required — the crowd is anonymous, same privilege level as the
// direct `requests` insert this replaces for paid tips.
//
// Required Vercel environment variables:
//   STRIPE_SECRET_KEY
// Optional (falls back to the production project if unset):
//   SUPABASE_URL, SUPABASE_ANON_KEY

import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://ykvpjeiakvgihpxektcf.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_g4w52upNnalAllmn8_8vRA_G6Hj-tlM';

// Floor for a paid tip. Was 0.5 (Stripe's own minimum charge); raised to the
// product minimum because client validation is a convenience and this is the
// control. The $0 "No Tip" path never reaches this function at all — it's a
// direct insert, so free requests are unaffected by this number.
const MIN_TIP = 3;
const MAX_TIP = 500; // sanity ceiling against a fat-fingered custom amount

// Statement descriptor (15-TECH-SCOPE Task 2). Stripe appends this suffix to
// the platform account's *shortened* descriptor, and the combined string is
// capped at 22 characters including the "PREFIX* " join, so the band's share
// is 20 minus the prefix length.
//
// The prefix is `BRIBEBAND` (9) -> 11 here. The scope originally specced
// `BTB-TIP` (7 -> 13), but Stripe rejected it: a shortened descriptor must
// resemble the business name or URL and may not be a product description,
// which "TIP" is. `BRIBETHEBAND` was the documented fallback but exceeds the
// 10-character ceiling on shortened descriptors. Confirmed accepted
// 2026-09-15. If the prefix ever changes, change this number with it.
const DESCRIPTOR_MAX = 11;
// Below this a word-boundary cut has thrown away so much that a hard cut at
// the limit carries more information — e.g. "A B VERYLONGWORD" should not
// become "A B".
const DESCRIPTOR_MIN_WORD_CUT = 8;

// "TEN CENT PROPHET" -> "TEN CENT". Cutting at a word boundary reads like a
// band name; a hard cut ("TEN CENT PROP") reads like a string that ran out of
// room, which is exactly the "what is this charge?" reaction this whole task
// exists to prevent.
function statementDescriptorSuffix(rawName) {
  const cleaned = String(rawName || '')
    // Fold accents to their base letter so "Café" becomes CAFE rather than
    // losing the character entirely — Stripe only accepts Latin here anyway.
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toUpperCase()
    .replace(/['\u2019]/g, '')       // drop apostrophes rather than split TRAVIS'S into TRAVIS S
    .replace(/[^A-Z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!cleaned) return null;         // omit the param entirely; never send ''
  if (cleaned.length <= DESCRIPTOR_MAX) return cleaned;
  const lastSpace = cleaned.lastIndexOf(' ', DESCRIPTOR_MAX);
  if (lastSpace >= DESCRIPTOR_MIN_WORD_CUT) return cleaned.slice(0, lastSpace);
  return cleaned.slice(0, DESCRIPTOR_MAX).trim();
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  if (!process.env.STRIPE_SECRET_KEY) {
    return res.status(500).json({ error: 'Payments are not configured on the server yet.' });
  }

  try {
    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch { body = {}; }
    }
    const { gig_session_id, song_id, song_title, note, is_tip_only } = body || {};
    const tipAmount = Number(body && body.tip_amount);

    if (!gig_session_id || typeof gig_session_id !== 'string') {
      return res.status(400).json({ error: 'Missing gig_session_id.' });
    }
    if (!(tipAmount >= MIN_TIP) || !(tipAmount <= MAX_TIP)) {
      return res.status(400).json({ error: `Tip must be between $${MIN_TIP.toFixed(2)} and $${MAX_TIP}.` });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Re-verify the gig session is real and still active.
    const { data: gig, error: gigError } = await supabase
      .from('gig_sessions')
      .select('id, status, performer_id, display_name_override')
      .eq('id', gig_session_id)
      .maybeSingle();
    if (gigError || !gig || gig.status !== 'active') {
      return res.status(400).json({ error: 'This gig is no longer active.' });
    }

    // Server-side cap/cooldown re-check, right before creating a charge —
    // reuses the exact same RPC the crowd page itself calls, so there's no
    // separate logic to drift out of sync. Never let someone pay for a
    // request that's guaranteed to be rejected as over-cap or on cooldown.
    // A song already in the active queue is never is_capped (boosting an
    // existing request bypasses the cap by design — see
    // migration-queue-cooldown-v1.sql), so this never blocks a real boost.
    if (song_id) {
      const { data: capRows, error: capError } = await supabase.rpc('get_song_request_status', {
        p_gig_session_id: gig_session_id,
      });
      const songStatus = !capError && (capRows || []).find((r) => r.song_id === song_id);
      if (songStatus && songStatus.in_cooldown) {
        return res.status(409).json({ error: 'This song was just played — it\'s on cooldown for a bit.' });
      }
      if (songStatus && songStatus.is_capped) {
        return res.status(409).json({ error: 'This song has already been requested plenty tonight.' });
      }
    }

    // Look up who actually receives this tip, and what cut (if any) the
    // platform takes — see migration-stripe-connect-v1.sql/v2.sql. A real
    // performer with no connected account yet can't take tips at all:
    // falling back to an unsplit charge into the platform's own account
    // would recreate the exact pooled-money problem Connect exists to
    // avoid, so this blocks instead of silently degrading. The house
    // account (Travis's own real account, flagged explicitly rather than
    // inferred from a null stripe_account_id — see v2's is_house_account)
    // is the one deliberate exception, staying on the original direct-
    // charge path with no Connect involvement at all.
    const { data: payoutRows, error: payoutError } = await supabase.rpc('get_performer_payout_info', {
      p_gig_session_id: gig_session_id,
    });
    if (payoutError) {
      return res.status(500).json({ error: 'Could not verify payout setup: ' + payoutError.message });
    }
    const payout = (payoutRows || [])[0];
    if (!payout) {
      return res.status(400).json({ error: 'Could not find this gig\'s performer.' });
    }
    if (!payout.is_house_account && !payout.stripe_account_id) {
      return res.status(400).json({ error: 'This performer hasn\'t set up payouts yet — tips can\'t be sent right now.' });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

    const paymentIntentParams = {
      amount: Math.round(tipAmount * 100),
      currency: 'usd',
      // Explicit 'card' (not automatic_payment_methods) so every enabled
      // method confirms synchronously — Apple Pay/Google Pay still surface
      // automatically in the Payment Element since they ride card rails.
      payment_method_types: ['card'],
      // Identity/routing only — the actual charged amount is always read
      // from Stripe's own confirmed total by the webhook, never metadata.
      metadata: {
        gig_session_id,
        song_id: song_id || '',
        song_title: song_title || '',
        note: note || '',
        is_tip_only: is_tip_only ? '1' : '0',
      },
    };

    // application_fee_amount is computed on the gross tip — Stripe's own
    // ~2.9%+30¢ processing fee comes out of the performer's share, not the
    // platform's cut (Travis's explicit choice when the numbers were locked
    // in — see 04-DECISIONS-AND-OPEN-QUESTIONS.md item 23).
    if (!payout.is_house_account) {
      paymentIntentParams.transfer_data = { destination: payout.stripe_account_id };
      paymentIntentParams.application_fee_amount = Math.round(tipAmount * 100 * (payout.fee_percentage / 100));
    }

    // Which name lands on the card statement: the gig's own override if the
    // performer set one, otherwise their account name. The override is what
    // the crowd page actually renders, so it's what was on the tipper's screen
    // at the moment they paid — and recognition days later attaches to what
    // they saw, not to whatever the account happens to be called.
    let descriptorName = (gig.display_name_override || '').trim();
    if (!descriptorName && gig.performer_id) {
      const { data: perf } = await supabase
        .from('performers')
        .select('display_name')
        .eq('id', gig.performer_id)
        .maybeSingle();
      descriptorName = (perf && perf.display_name) || '';
    }
    const descriptorSuffix = statementDescriptorSuffix(descriptorName);
    if (descriptorSuffix) paymentIntentParams.statement_descriptor_suffix = descriptorSuffix;

    let paymentIntent;
    try {
      paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);
    } catch (err) {
      // A suffix only works once the platform account has a shortened
      // descriptor configured in the Stripe dashboard, and Stripe rejects some
      // suffix content outright. Neither should ever cost a real tip at a real
      // gig: drop the suffix and retry once, so the charge still goes through
      // with the default descriptor.
      const msg = String((err && err.message) || '').toLowerCase();
      const isDescriptorProblem =
        (err && err.param && String(err.param).includes('statement_descriptor')) ||
        msg.includes('statement descriptor') ||
        msg.includes('statement_descriptor');
      if (!isDescriptorProblem || !paymentIntentParams.statement_descriptor_suffix) throw err;
      console.warn('statement_descriptor_suffix rejected, retrying without it:', err.message);
      delete paymentIntentParams.statement_descriptor_suffix;
      paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);
    }

    return res.status(200).json({ client_secret: paymentIntent.client_secret });
  } catch (err) {
    console.error('create-payment-intent error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
