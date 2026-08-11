// Vercel serverless function: issues a short-lived presigned PUT URL so a
// logged-in performer's browser can upload a chart PDF directly to Wasabi,
// without ever exposing the Wasabi secret key to the client.
//
// Required Vercel environment variables (set in Project → Settings →
// Environment Variables — never commit real values to git):
//   WASABI_ACCESS_KEY_ID
//   WASABI_SECRET_ACCESS_KEY
// Optional (defaults shown match the existing bucket):
//   WASABI_BUCKET     (default: songchart)
//   WASABI_REGION     (default: us-east-1)
//   WASABI_ENDPOINT   (default: https://s3.us-east-1.wasabisys.com)

import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ykvpjeiakvgihpxektcf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_g4w52upNnalAllmn8_8vRA_G6Hj-tlM';

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
    forcePathStyle: true, // matches existing chart_url pattern: {endpoint}/{bucket}/{key}
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

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Validate the token and find the performer it belongs to. We look the
    // performer up ourselves (rather than trusting anything from the
    // request body) so nobody can upload into another performer's folder.
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

    const key = `charts/${performer.id}/${songSlug}.pdf`;

    const command = new PutObjectCommand({
      Bucket: WASABI_BUCKET,
      Key: key,
      ContentType: 'application/pdf',
    });

    const s3 = getS3Client();
    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
    const publicUrl = `${WASABI_ENDPOINT}/${WASABI_BUCKET}/${key}`;

    return res.status(200).json({ uploadUrl, publicUrl, key });
  } catch (err) {
    console.error('wasabi-upload-url error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
