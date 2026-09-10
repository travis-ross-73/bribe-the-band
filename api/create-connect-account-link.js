// Vercel serverless function: creates (or reuses) a Stripe Express connected
// account for the calling performer, then returns a fresh Stripe-hosted
// onboarding link. Authenticated — unlike the tip-flow endpoints, this one
// has to know exactly which performer is calling.
//
// Required Vercel environment variables:
//   STRIPE_SECRET_KEY
// Optional (falls back to the production project if unset):
//   SUPABASE_URL, SUPABASE_ANON_KEY
//
// Requires migration-stripe-connect-v1.sql (stripe_account_id/
// stripe_onboarding_status/fee_percentage on performers, plus the
// get_my_stripe_connect_status()/set_my_stripe_connect_status() RPCs).

import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://ykvpjeiakvgihpxektcf.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_g4w52upNnalAllmn8_8vRA_G6Hj-tlM';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  if (!process.env.STRIPE_SECRET_KEY) {
    return res.status(500).json({ error: 'Payments are not configured on the server yet.' });
  }

  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.replace(/^Bearer\s+/i, '');
    if (!token) return res.status(401).json({ error: 'Missing auth token.' });

    // Attach the caller's own token so RPC calls run as `authenticated` with
    // their identity — same pattern as wasabi-upload-url.js.
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData || !userData.user) {
      return res.status(401).json({ error: 'Invalid or expired session — please log in again.' });
    }

    const { data: performer, error: performerError } = await supabase
      .from('performers')
      .select('id')
      .eq('auth_user_id', userData.user.id)
      .maybeSingle();

    if (performerError || !performer) {
      return res.status(403).json({ error: 'No performer profile linked to this account.' });
    }

    // Reuse an existing connected account if one's already been started —
    // a resumed onboarding and an expired account-link "refresh" both land
    // here through the same button, so this has to be idempotent rather
    // than creating a second Stripe account for the same performer.
    const { data: statusRows, error: statusError } = await supabase.rpc('get_my_stripe_connect_status');
    if (statusError) {
      return res.status(500).json({ error: 'Could not check existing Stripe status: ' + statusError.message });
    }
    const existing = (statusRows || [])[0];

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    let stripeAccountId = existing && existing.stripe_account_id;

    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        country: 'US',
        email: userData.user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
      });
      stripeAccountId = account.id;

      const { error: setError } = await supabase.rpc('set_my_stripe_connect_status', {
        p_stripe_account_id: stripeAccountId,
        p_status: 'pending',
      });
      if (setError) {
        return res.status(500).json({ error: 'Could not save the new Stripe account: ' + setError.message });
      }
    }

    const origin = req.headers.origin || `https://${req.headers.host}`;
    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: `${origin}/console.html?stripe_connect=refresh`,
      return_url: `${origin}/console.html?stripe_connect=return`,
      type: 'account_onboarding',
    });

    return res.status(200).json({ url: accountLink.url });
  } catch (err) {
    console.error('create-connect-account-link error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
