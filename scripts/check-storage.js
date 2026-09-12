const fs = require('fs');
const path = require('path');

const envPath = path.resolve(__dirname, '../apps/web/.env.local');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;
  const eqIdx = trimmed.indexOf('=');
  if (eqIdx !== -1) {
    env[trimmed.slice(0, eqIdx).trim()] = trimmed.slice(eqIdx + 1).trim();
  }
});

const { createClient } = require(path.resolve(__dirname, '../apps/web/node_modules/@supabase/supabase-js'));

async function inspectBucketFiles() {
  const client = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  await client.auth.signInWithPassword({
    email: 'owner@snip.demo',
    password: 'SnipPassword123!',
  });
  const { data: files, error } = await client.storage.from('salon-images').list();
  console.log('List salon-images:', { files, error });
}

inspectBucketFiles().catch(console.error);
