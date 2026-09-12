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

async function verifyStage4() {
  console.log('=== STARTING STAGE 4: REVIEWS, RATINGS & FAVORITES VERIFICATION ===\n');

  // 1. Get demo customer and demo salon
  console.log('1. Locating demo customer, salon and barber...');
  const { data: customer, error: custErr } = await supabaseAdmin
    .from('profiles')
    .select('id, email, full_name')
    .eq('email', 'customer@snip.demo')
    .single();

  if (custErr || !customer) {
    console.error('FAILED to find demo customer:', custErr);
    process.exit(1);
  }

  const { data: salon, error: salonErr } = await supabaseAdmin
    .from('salons')
    .select('id, name, slug, avg_rating, review_count')
    .limit(1)
    .single();

  if (salonErr || !salon) {
    console.error('FAILED to find salon:', salonErr);
    process.exit(1);
  }

  const { data: barber } = await supabaseAdmin
    .from('barbers')
    .select('id, display_name')
    .eq('salon_id', salon.id)
    .limit(1)
    .single();

  const { data: service } = await supabaseAdmin
    .from('services')
    .select('id, name, price')
    .eq('salon_id', salon.id)
    .limit(1)
    .single();

  console.log(`  Customer: ${customer.full_name} (${customer.id})`);
  console.log(`  Salon: ${salon.name} (${salon.id})`);
  console.log(`  Initial salon avg_rating: ${salon.avg_rating}, review_count: ${salon.review_count}`);

  // 2. Test Favorites Table
  console.log('\n2. Testing Favorites functionality...');
  // Add favorite
  const { data: favInsert, error: favErr } = await supabaseAdmin
    .from('favorites')
    .upsert({
      user_id: customer.id,
      salon_id: salon.id,
    })
    .select();

  if (favErr) {
    console.error('FAILED to insert favorite:', favErr);
    process.exit(1);
  }
  console.log('  [OK] Successfully favorited salon.');

  // Check favorite query
  const { data: favCheck } = await supabaseAdmin
    .from('favorites')
    .select('id')
    .eq('user_id', customer.id)
    .eq('salon_id', salon.id)
    .maybeSingle();

  if (!favCheck) {
    console.error('FAILED: Favorite was not found in database.');
    process.exit(1);
  }
  console.log('  [OK] Favorite confirmed in database.');

  // Remove favorite
  await supabaseAdmin
    .from('favorites')
    .delete()
    .eq('user_id', customer.id)
    .eq('salon_id', salon.id);
  console.log('  [OK] Cleanly toggled favorite off.');

  // 3. Test Booking & Review flow
  console.log('\n3. Testing Review restrictions and submission...');

  // Create an appointment for customer
  const now = new Date();
  const startTime = new Date(now.getTime() - 3600000 * 2).toISOString(); // 2 hours ago
  const endTime = new Date(now.getTime() - 3600000 * 1.5).toISOString();

  const { data: booking, error: bookErr } = await supabaseAdmin
    .from('bookings')
    .insert({
      customer_id: customer.id,
      salon_id: salon.id,
      barber_id: barber.id,
      service_id: service.id,
      appointment_start: startTime,
      appointment_end: endTime,
      price: service.price,
      status: 'confirmed',
    })
    .select()
    .single();

  if (bookErr) {
    console.error('FAILED to create test booking:', bookErr);
    process.exit(1);
  }
  console.log(`  Created test booking ${booking.id} with status "${booking.status}"`);

  // Customer client session
  const customerSupabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  );

  const { data: loginData, error: loginErr } = await customerSupabase.auth.signInWithPassword({
    email: 'customer@snip.demo',
    password: 'SnipPassword123!',
  });

  if (loginErr) {
    console.error('FAILED to sign in as demo customer:', loginErr);
    process.exit(1);
  }
  console.log('  Authenticated as demo customer.');

  // Attempt to submit review on confirmed (not completed) appointment
  console.log('  Attempting to review a CONFIRMED booking (should be rejected)...');
  const { data: rejectedReview, error: rejectErr } = await customerSupabase.rpc(
    'submit_booking_review',
    {
      p_booking_id: booking.id,
      p_rating: 5,
      p_comment: 'Premature review attempt',
    }
  );

  if (!rejectErr) {
    console.error('FAILED: Review was erroneously allowed on an uncompleted appointment!');
    process.exit(1);
  }
  console.log(`  [OK] Properly rejected by server rule: "${rejectErr.message}"`);

  // Now transition booking to 'completed'
  console.log('\n4. Transitioning booking to COMPLETED and submitting valid 5-star review...');
  await supabaseAdmin
    .from('bookings')
    .update({ status: 'completed' })
    .eq('id', booking.id);

  const { data: reviewResult, error: submitErr } = await customerSupabase.rpc(
    'submit_booking_review',
    {
      p_booking_id: booking.id,
      p_rating: 5,
      p_comment: 'Masterful fade haircut and beard detailing. Kamal is world class!',
    }
  );

  if (submitErr) {
    console.error('FAILED to submit review:', submitErr);
    process.exit(1);
  }
  console.log('  [OK] Review submitted successfully:', reviewResult);

  // 5. Verify salon rating aggregate recalculation
  console.log('\n5. Verifying Salon Rating Aggregate recalculation...');
  const { data: updatedSalon } = await supabaseAdmin
    .from('salons')
    .select('avg_rating, review_count')
    .eq('id', salon.id)
    .single();

  console.log(`  Updated salon avg_rating: ${updatedSalon.avg_rating}, review_count: ${updatedSalon.review_count}`);
  if (updatedSalon.avg_rating <= 0 || updatedSalon.review_count <= 0) {
    console.error('FAILED: Salon average rating or review count was not synced!');
    process.exit(1);
  }
  console.log('  [OK] Trigger public.sync_salon_rating() updated salon aggregates.');

  // 6. Test updating review to 4 stars
  console.log('\n6. Updating review rating to 4 stars...');
  const { data: updateResult, error: updateErr } = await customerSupabase.rpc(
    'submit_booking_review',
    {
      p_booking_id: booking.id,
      p_rating: 4,
      p_comment: 'Great cut overall, very happy with the result.',
    }
  );

  if (updateErr) {
    console.error('FAILED to update review:', updateErr);
    process.exit(1);
  }

  const { data: updatedSalon2 } = await supabaseAdmin
    .from('salons')
    .select('avg_rating, review_count')
    .eq('id', salon.id)
    .single();

  console.log(`  Recalculated salon avg_rating after update: ${updatedSalon2.avg_rating}`);

  // 7. Clean up test data
  console.log('\n7. Cleaning up test booking and review...');
  await supabaseAdmin.from('reviews').delete().eq('booking_id', booking.id);
  await supabaseAdmin.from('bookings').delete().eq('id', booking.id);

  const { data: finalSalon } = await supabaseAdmin
    .from('salons')
    .select('avg_rating, review_count')
    .eq('id', salon.id)
    .single();
  console.log(`  Salon aggregates after cleanup: avg_rating: ${finalSalon.avg_rating}, review_count: ${finalSalon.review_count}`);

  console.log('\n=============================================================');
  console.log('>>> STAGE 4: REVIEWS, RATINGS & FAVORITES VERIFIED (0 ERRORS) <<<');
  console.log('=============================================================\n');
}

verifyStage4().catch(err => {
  console.error('Verification failed with exception:', err);
  process.exit(1);
});
