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

const supabase = createClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY
);

async function verifyStage3Storage() {
  console.log('=== STARTING STAGE 3 STORAGE INTEGRATION VERIFICATION ===\n');

  // 1. Verify Storage Buckets
  console.log('1. Checking storage buckets...');
  const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
  if (bucketError) {
    console.error('FAILED to list buckets:', bucketError);
    process.exit(1);
  }
  const bucketNames = buckets.map(b => b.name);
  console.log('Found buckets:', bucketNames.join(', '));

  const requiredBuckets = ['avatars', 'salon-images', 'service-images', 'barber-portfolios'];
  for (const req of requiredBuckets) {
    if (bucketNames.includes(req)) {
      console.log(`  [OK] Bucket "${req}" exists.`);
    } else {
      console.error(`  [FAIL] Missing required bucket "${req}".`);
      process.exit(1);
    }
  }

  // 2. Test uploading a 1x1 PNG to 'salon-images'
  console.log('\n2. Testing upload to "salon-images"...');
  const dummyPng = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    'base64'
  );
  const testFileName = `test/verify_${Date.now()}.png`;
  const { data: uploadData, error: uploadError } = await supabase.storage
    .from('salon-images')
    .upload(testFileName, dummyPng, {
      contentType: 'image/png',
      upsert: true,
    });

  if (uploadError) {
    console.error('FAILED to upload image:', uploadError);
    process.exit(1);
  }
  console.log('  [OK] Image uploaded successfully:', uploadData.path);

  // 3. Test public URL generation
  console.log('\n3. Testing public URL generation...');
  const { data: { publicUrl } } = supabase.storage
    .from('salon-images')
    .getPublicUrl(testFileName);
  console.log('  [OK] Public URL resolved:', publicUrl);

  // 4. Test uploading an avatar to 'avatars'
  console.log('\n4. Testing avatar upload to "avatars"...');
  const avatarFileName = `test_user/avatar_${Date.now()}.png`;
  const { error: avatarError } = await supabase.storage
    .from('avatars')
    .upload(avatarFileName, dummyPng, {
      contentType: 'image/png',
      upsert: true,
    });

  if (avatarError) {
    console.error('FAILED to upload avatar:', avatarError);
    process.exit(1);
  }
  console.log('  [OK] Avatar uploaded successfully to "avatars".');

  // 5. Clean up uploaded test files
  console.log('\n5. Cleaning up test files...');
  await supabase.storage.from('salon-images').remove([testFileName]);
  await supabase.storage.from('avatars').remove([avatarFileName]);
  console.log('  [OK] Cleaned up temporary test files from storage.');

  console.log('\n======================================================');
  console.log('>>> STAGE 3 STORAGE INTEGRATION VERIFIED WITH 0 ERRORS <<<');
  console.log('======================================================\n');
}

verifyStage3Storage().catch(err => {
  console.error('Verification failed with exception:', err);
  process.exit(1);
});
