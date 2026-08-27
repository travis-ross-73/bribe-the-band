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

const MIN_TIP = 0.5; // Stripe's real minimum charge
const MAX_TIP = 500; // sanity ceiling against a fat-fingered custom amount

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
      .select('id, status')
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

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

    const paymentIntent = await stripe.paymentIntents.create({
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
    });

    return res.status(200).json({ client_secret: paymentIntent.client_secret });
  } catch (err) {
    console.error('create-payment-intent error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
