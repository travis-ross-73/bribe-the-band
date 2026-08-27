// Vercel serverless function: deletes a chart PDF from Wasabi when a
// performer removes a song from their catalog in the console. Mirrors the
// auth pattern in wasabi-upload-url.js — verifies the caller's Supabase
// session and looks up their own performer row itself, so nobody can delete
// another performer's files.
//
// Uses the same Vercel environment variables as wasabi-upload-url.js:
//   WASABI_ACCESS_KEY_ID, WASABI_SECRET_ACCESS_KEY
//   WASABI_BUCKET (default: songchart), WASABI_REGION (default: us-east-1)
//   WASABI_ENDPOINT (default: https://s3.us-east-1.wasabisys.com)

import { S3Client, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://ykvpjeiakvgihpxektcf.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_g4w52upNnalAllmn8_8vRA_G6Hj-tlM';

const WASABI_BUCKET = process.env.WASABI_BUCKET || 'songchart';
const WASABI_REGION = process.env.WASABI_REGION || 'us-east-1';
const WASABI_ENDPOINT = process.env.WASABI_ENDPOINT || `https://s3.${WASABI_REGION}.wasabisys.com`;

function getS3Client() {
  return new S3Client({
    endpoint: WASABI_ENDPOINT,
    region: WASABI_REGION,
    credentials: {
      accessKeyId: process.env.WASABI_ACCESS_KEY_ID,
      secretAccessKey: process.env.WASABI_SECRET_ACCESS_KEY,
    },
    forcePathStyle: true,
  });
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  if (!process.env.WASABI_ACCESS_KEY_ID || !process.env.WASABI_SECRET_ACCESS_KEY) {
    return res.status(500).json({ error: 'Wasabi credentials are not configured on the server yet.' });
  }

  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.replace(/^Bearer\s+/i, '');
    if (!token) return res.status(401).json({ error: 'Missing auth token.' });

    // Attach the caller's own token so subsequent queries run as
    // `authenticated` (with their RLS/column grants), not `anon` — matching
    // auth.getUser(token) alone does NOT do this for a client's later calls.
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

    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch { body = {}; }
    }
    const songSlug = body && body.songSlug;
    if (!songSlug || typeof songSlug !== 'string' || !/^[a-z0-9-]+$/.test(songSlug)) {
      return res.status(400).json({ error: 'Missing or invalid songSlug (lowercase letters, numbers, hyphens only).' });
    }

    // Scoped to this performer's own folder only — same rule as the upload function.
    const key = `charts/${performer.id}/${songSlug}.pdf`;

    const s3 = getS3Client();
    await s3.send(new DeleteObjectCommand({ Bucket: WASABI_BUCKET, Key: key }));

    return res.status(200).json({ deleted: true, key });
  } catch (err) {
    console.error('wasabi-delete-chart error', err);
    // Not fatal to the caller — the console treats this as best-effort and
    // still proceeds with removing the catalog row either way.
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
