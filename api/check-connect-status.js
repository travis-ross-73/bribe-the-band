// Vercel serverless function: re-checks the calling performer's Stripe
// Express account (charges_enabled/payouts_enabled) against Stripe's own
// records and updates performers.stripe_onboarding_status to match. Called
// when the performer lands back on console.html after Stripe's hosted
// onboarding flow (see create-connect-account-link.js's return_url).
//
// Required Vercel environment variables:
//   STRIPE_SECRET_KEY
// Optional (falls back to the production project if unset):
//   SUPABASE_URL, SUPABASE_ANON_KEY
//
// Requires migration-stripe-connect-v1.sql, same as
// create-connect-account-link.js.

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

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData || !userData.user) {
      return res.status(401).json({ error: 'Invalid or expired session — please log in again.' });
    }

    const { data: statusRows, error: statusError } = await supabase.rpc('get_my_stripe_connect_status');
    if (statusError) {
      return res.status(500).json({ error: 'Could not load Stripe status: ' + statusError.message });
    }
    const existing = (statusRows || [])[0];
    if (!existing || !existing.stripe_account_id) {
      return res.status(400).json({ error: 'No Stripe account has been started for this performer yet.' });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const account = await stripe.accounts.retrieve(existing.stripe_account_id);

    // Stripe's own flags, collapsed to this app's simpler status enum.
    // requirements.disabled_reason catches an account Stripe has flagged
    // (fraud review, missing info past a deadline, etc.) — surfaced as
    // 'restricted' rather than silently staying 'pending' forever.
    let status = 'pending';
    if (account.requirements && account.requirements.disabled_reason) {
      status = 'restricted';
    } else if (account.charges_enabled && account.payouts_enabled) {
      status = 'complete';
    }

    const { error: setError } = await supabase.rpc('set_my_stripe_connect_status', {
      p_stripe_account_id: existing.stripe_account_id,
      p_status: status,
    });
    if (setError) {
      return res.status(500).json({ error: 'Could not save updated status: ' + setError.message });
    }

    return res.status(200).json({ status });
  } catch (err) {
    console.error('check-connect-status error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
