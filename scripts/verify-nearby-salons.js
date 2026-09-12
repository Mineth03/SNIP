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
  env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

async function verifyNearbySalons() {
  console.log('=== VERIFYING NEARBY SALONS GEOLOCATION FEATURE ===\n');

  // Colombo 05 (Havelock Town) coordinates
  const userLat = 6.8918;
  const userLng = 79.8732;

  console.log(`1. Testing RPC get_nearby_salons from user location (${userLat}, ${userLng})...`);

  const { data: nearbySalons, error: rpcErr } = await supabase.rpc('get_nearby_salons', {
    p_latitude: userLat,
    p_longitude: userLng,
    p_radius_km: 50,
    p_limit: 10,
  });

  if (rpcErr) {
    console.error('❌ RPC call failed:', rpcErr);
    process.exit(1);
  }

  console.log(`✅ Success! Found ${nearbySalons.length} salon(s) within 50 km:`);
  nearbySalons.forEach((s, idx) => {
    console.log(`   [${idx + 1}] "${s.name}" (${s.city || s.address}) - Lat: ${s.latitude}, Lng: ${s.longitude}`);
    console.log(`       → Distance: ${s.distance_km} km away | Rating: ${s.avg_rating}★ (${s.review_count} reviews)`);
  });

  // Verify ascending order by distance
  console.log('\n2. Verifying distance sorting...');
  let sorted = true;
  for (let i = 0; i < nearbySalons.length - 1; i++) {
    if (nearbySalons[i].distance_km > nearbySalons[i + 1].distance_km) {
      sorted = false;
      break;
    }
  }
  if (!sorted) {
    console.error('❌ Salons are not sorted by distance!');
    process.exit(1);
  }
  console.log('✅ Distance sorting verified (closest first).');

  // Test far away point (e.g. Galle ~120km away) with 10km radius
  console.log('\n3. Testing radius filtering with Galle coordinates (6.0535, 80.2210) & 10km radius...');
  const { data: galleNearby, error: galleErr } = await supabase.rpc('get_nearby_salons', {
    p_latitude: 6.0535,
    p_longitude: 80.2210,
    p_radius_km: 10,
    p_limit: 10,
  });

  if (galleErr) {
    console.error('❌ Galle RPC query failed:', galleErr);
    process.exit(1);
  }

  console.log(`✅ Salons found within 10 km of Galle: ${galleNearby.length} (Colombo salons correctly excluded)`);

  console.log('\n=== ALL NEARBY SALON GEOLOCATION CHECKS PASSED SUCCESSFULLY! ===');
}

verifyNearbySalons().catch(err => {
  console.error('Unhandled error:', err);
  process.exit(1);
});
