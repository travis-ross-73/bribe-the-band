// One-time migration helper: moves chart PDFs out of the old
// handle-based Wasabi folder (charts/{handle}/...) — used only for the
// original 50 seed songs, uploaded before the app existed — into the
// ID-based folder (charts/{performer.id}/...) that every upload/replace/
// delete function has used since. Also cleans up any leftover originals
// for songs that were already replaced through the console (those already
// have a newer file sitting correctly in the ID folder).
//
// Safe to run more than once — anything already migrated is skipped
// rather than re-copied, so it never clobbers a newer replacement with an
// older original.
//
// Same env vars as the other Wasabi functions:
//   WASABI_ACCESS_KEY_ID, WASABI_SECRET_ACCESS_KEY
//   WASABI_BUCKET (default: songchart), WASABI_REGION (default: us-east-1)
//   WASABI_ENDPOINT (default: https://s3.us-east-1.wasabisys.com)

import {
  S3Client,
  ListObjectsV2Command,
  HeadObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
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
    forcePathStyle: true,
  });
}

async function objectExists(s3, key) {
  try {
    await s3.send(new HeadObjectCommand({ Bucket: WASABI_BUCKET, Key: key }));
    return true;
  } catch (err) {
    return false;
  }
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

    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData || !userData.user) {
      return res.status(401).json({ error: 'Invalid or expired session — please log in again.' });
    }

    const { data: performer, error: performerError } = await supabase
      .from('performers')
      .select('id, handle')
      .eq('auth_user_id', userData.user.id)
      .maybeSingle();

    if (performerError || !performer) {
      return res.status(403).json({ error: 'No performer profile linked to this account.' });
    }

    const s3 = getS3Client();
    const oldPrefix = `charts/${performer.handle}/`;
    const newPrefix = `charts/${performer.id}/`;

    // List every file sitting in the old handle-based folder.
    let oldKeys = [];
    let continuationToken;
    do {
      const listRes = await s3.send(new ListObjectsV2Command({
        Bucket: WASABI_BUCKET,
        Prefix: oldPrefix,
        ContinuationToken: continuationToken,
      }));
      (listRes.Contents || []).forEach(obj => oldKeys.push(obj.Key));
      continuationToken = listRes.IsTruncated ? listRes.NextContinuationToken : undefined;
    } while (continuationToken);

    const results = { migrated: [], alreadyUpToDate: [], errors: [] };

    for (const oldKey of oldKeys) {
      const filename = oldKey.slice(oldPrefix.length); // e.g. "wonderwall.pdf"
      if (!filename.toLowerCase().endsWith('.pdf')) continue;
      const slug = filename.replace(/\.pdf$/i, '');
      const newKey = `${newPrefix}${filename}`;

      try {
        const alreadyMigrated = await objectExists(s3, newKey);

        if (!alreadyMigrated) {
          // Copy the original into the new ID-based folder, then point the
          // database at it.
          await s3.send(new CopyObjectCommand({
            Bucket: WASABI_BUCKET,
            CopySource: `/${WASABI_BUCKET}/${encodeURIComponent(oldKey)}`,
            Key: newKey,
            ContentType: 'application/pdf',
          }));

          const newPublicUrl = `${WASABI_ENDPOINT}/${WASABI_BUCKET}/${newKey}`;
          const { error: updateError } = await supabase
            .from('songs')
            .update({ chart_url: newPublicUrl })
            .eq('id', slug)
            .eq('performer_id', performer.id);

          if (updateError) {
            results.errors.push(`${filename}: copied but couldn't update database (${updateError.message}). Not deleting the original as a precaution.`);
            continue;
          }
          results.migrated.push(filename);
        } else {
          results.alreadyUpToDate.push(filename);
        }

        // Either way, the old file's job is done — remove it.
        await s3.send(new DeleteObjectCommand({ Bucket: WASABI_BUCKET, Key: oldKey }));
      } catch (err) {
        results.errors.push(`${filename}: ${err && err.message ? err.message : 'unknown error'}`);
      }
    }

    return res.status(200).json(results);
  } catch (err) {
    console.error('migrate-legacy-charts error', err);
    return res.status(500).json({ error: err && err.message ? err.message : 'Unknown server error.' });
  }
}
