// Vercel serverless function: Stripe webhook. This is the ONLY place a paid
// request ever gets written to the `requests` table — nothing is inserted
// at PaymentIntent-creation time, so a failed/abandoned payment simply never
// produces a row (no expiry/cleanup logic needed for incomplete payments).
//
// Required Vercel environment variables:
//   STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET
// Optional (falls back to the production project if unset):
//   SUPABASE_URL, SUPABASE_ANON_KEY
//
// Requires `stripe_payment_intent_id text unique` on `requests`
// (see migration-stripe-v1.sql) for webhook-retry idempotency.

import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://ykvpjeiakvgihpxektcf.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_g4w52upNnalAllmn8_8vRA_G6Hj-tlM';

export const config = { api: { bodyParser: false } };

function readRawBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_WEBHOOK_SECRET) {
    return res.status(500).json({ error: 'Stripe is not configured on the server yet.' });
  }

  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

  let event;
  try {
    const rawBody = await readRawBody(req);
    const signature = req.headers['stripe-signature'];
    event = stripe.webhooks.constructEvent(rawBody, signature, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Stripe webhook signature verification failed', err.message);
    return res.status(400).json({ error: `Webhook Error: ${err.message}` });
  }

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    const metadata = paymentIntent.metadata || {};
    const gigSessionId = metadata.gig_session_id;

    if (gigSessionId) {
      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      const { error } = await supabase.from('requests').insert({
        gig_session_id: gigSessionId,
        song_id: metadata.song_id || null,
        tip_amount: (paymentIntent.amount_received || paymentIntent.amount || 0) / 100,
        note: metadata.note || null,
        status: 'pending',
        stripe_payment_intent_id: paymentIntent.id,
      });

      if (error) {
        if (error.code === '23505') {
          // Unique violation on stripe_payment_intent_id — Stripe's webhook
          // delivery is at-least-once, so a retry of an already-processed
          // event is expected, not an error. Acknowledge so it stops retrying.
          return res.status(200).json({ received: true, note: 'duplicate delivery, already processed' });
        }
        console.error('Failed to insert paid request', error);
        // Any other error: return 500 so Stripe retries delivery rather
        // than silently dropping a request someone already paid for.
        return res.status(500).json({ error: 'Failed to record request.' });
      }
    }
  }

  // Deliberately no handling for cap status here — money has already
  // changed hands by the time this fires, so the request is recorded
  // unconditionally regardless of whether the song is now over-cap.
  return res.status(200).json({ received: true });
}
