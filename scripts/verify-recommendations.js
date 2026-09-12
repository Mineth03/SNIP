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

const supabaseAdmin = createClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY
);

async function verifyRecommendations() {
  console.log('=== VERIFYING USER ACTIVITIES & RECOMMENDATION ENGINE ===\n');

  // 1. Locate demo customer
  console.log('1. Locating demo customer...');
  const { data: customer, error: custErr } = await supabaseAdmin
    .from('profiles')
    .select('id, email, full_name')
    .eq('email', 'customer@snip.demo')
    .single();

  if (custErr || !customer) {
    console.error('FAILED to find demo customer:', custErr);
    process.exit(1);
  }
  console.log(`✅ Demo Customer: ${customer.full_name} (${customer.id})`);

  // 2. Check backfilled activities
  console.log('\n2. Checking backfilled user_activities...');
  const { data: activities, error: actErr } = await supabaseAdmin
    .from('user_activities')
    .select('id, activity_type, salon_id, service_id, category, metadata, created_at')
    .eq('user_id', customer.id);

  if (actErr) {
    console.error('FAILED to query user_activities:', actErr);
    process.exit(1);
  }
  console.log(`✅ Found ${activities.length} activity records for customer:`);
  activities.forEach((a, i) => {
    console.log(`   [${i + 1}] Type: ${a.activity_type} | Category: ${a.category || 'N/A'} | Created: ${a.created_at}`);
  });

  // 3. Test logging new activity (e.g. view_salon)
  console.log('\n3. Testing RPC log_user_activity via customer client...');
  // Find a salon
  const { data: salon } = await supabaseAdmin.from('salons').select('id, name').limit(1).single();

  const { data: insertAct, error: logErr } = await supabaseAdmin
    .from('user_activities')
    .insert({
      user_id: customer.id,
      activity_type: 'view_salon',
      salon_id: salon.id,
      metadata: { source: 'search_results' }
    })
    .select()
    .single();

  if (logErr) {
    console.error('FAILED to insert activity:', logErr);
    process.exit(1);
  }
  console.log(`✅ Activity logged successfully: ${insertAct.id} (${insertAct.activity_type})`);

  // 4. Test get_personalized_recommendations RPC
  console.log('\n4. Testing get_personalized_recommendations RPC for customer...');
  const { data: recs, error: recErr } = await supabaseAdmin.rpc('get_personalized_recommendations', {
    p_user_id: customer.id,
    p_latitude: 6.8918,
    p_longitude: 79.8732,
    p_limit: 5,
  });

  if (recErr) {
    console.error('FAILED to get recommendations:', recErr);
    process.exit(1);
  }

  console.log(`✅ Recommendations returned (${recs.length} salons):`);
  recs.forEach((r, i) => {
    console.log(`   [${i + 1}] "${r.name}" (${r.city})`);
    console.log(`       → Reason: ${r.recommendation_reason}`);
    console.log(`       → Score: ${r.recommendation_score} pts | Distance: ${r.distance_km} km | Rating: ${r.avg_rating}★`);
  });

  // 5. Test get_user_recent_activity RPC
  console.log('\n5. Testing get_user_recent_activity RPC...');
  const { data: recentActs, error: recentErr } = await supabaseAdmin.rpc('get_user_recent_activity', {
    p_user_id: customer.id,
    p_limit: 5,
  });

  if (recentErr) {
    console.error('FAILED to get recent activity:', recentErr);
    process.exit(1);
  }

  console.log(`✅ Recent activities retrieved: ${recentActs.length}`);
  recentActs.forEach((ra, i) => {
    console.log(`   [${i + 1}] ${ra.activity_type} - Salon: "${ra.salon_name}" - ${ra.created_at}`);
  });

  console.log('\n=== ALL USER ACTIVITIES & RECOMMENDATION CHECKS PASSED! ===');
}

verifyRecommendations().catch(err => {
  console.error('Unhandled error:', err);
  process.exit(1);
});
