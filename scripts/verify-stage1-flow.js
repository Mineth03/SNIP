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

async function testStage1Flow() {
  console.log('=== STARTING STAGE 1 END-TO-END VERIFICATION ===\n');

  // 1. Authenticate as Customer
  const customerClient = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const { data: custAuth, error: custAuthErr } = await customerClient.auth.signInWithPassword({
    email: 'customer@snip.demo',
    password: 'SnipPassword123!',
  });
  if (custAuthErr) {
    console.error('Customer login failed:', custAuthErr);
    return;
  }
  console.log('1. ✓ Customer logged in:', custAuth.user.email);

  // 2. Fetch Salon & Service
  const { data: salon } = await customerClient.from('salons').select('id, name').eq('slug', 'the-modern-cut').single();
  const { data: service } = await customerClient.from('services').select('id, name, duration_minutes').eq('salon_id', salon.id).eq('name', "Men's Haircut").single();
  const { data: barber } = await customerClient.from('barbers').select('id, display_name').eq('salon_id', salon.id).single();

  console.log(`2. ✓ Salon & Service identified: ${salon.name} | ${service.name} | Barber: ${barber.display_name}`);

  // 3. Query Slots for future day
  const testDate = new Date();
  testDate.setDate(testDate.getDate() + 5);
  const dateStr = testDate.toISOString().slice(0, 10);

  const { data: slots, error: slotsErr } = await customerClient.rpc('get_available_slots', {
    p_salon_id: salon.id,
    p_service_id: service.id,
    p_barber_id: barber.id,
    p_date: dateStr,
    p_slot_interval_minutes: 30,
    p_buffer_minutes: 0,
  });

  if (slotsErr || !slots || slots.length === 0) {
    console.error('Failed to get slots:', slotsErr);
    return;
  }
  const chosenSlot = slots[0];
  console.log(`3. ✓ Chosen available slot: ${chosenSlot.slot_start} -> ${chosenSlot.slot_end}`);

  // 4. Create Booking
  const { data: newBooking, error: bookErr } = await customerClient.rpc('create_booking', {
    p_salon_id: salon.id,
    p_service_id: service.id,
    p_appointment_start: chosenSlot.slot_start,
    p_barber_id: chosenSlot.barber_id,
    p_customer_notes: 'Stage 1 Verification Test Booking',
  });

  if (bookErr) {
    console.error('Booking creation error:', bookErr);
    return;
  }
  console.log(`4. ✓ Booking created! ID: ${newBooking.id} | Status: ${newBooking.status} | QR Token: ${newBooking.qr_token}`);

  // 5. Test Double-Booking Prevention
  const { error: doubleBookErr } = await customerClient.rpc('create_booking', {
    p_salon_id: salon.id,
    p_service_id: service.id,
    p_appointment_start: chosenSlot.slot_start,
    p_barber_id: chosenSlot.barber_id,
  });
  if (doubleBookErr) {
    console.log(`5. ✓ Double-booking correctly blocked! Error: "${doubleBookErr.message}"`);
  } else {
    console.error('5. ✗ Double booking was not blocked!');
  }

  // 6. Authenticate as Barber (Kamal)
  const barberClient = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const { data: bAuth, error: bAuthErr } = await barberClient.auth.signInWithPassword({
    email: 'barber@snip.demo',
    password: 'SnipPassword123!',
  });
  if (bAuthErr) {
    console.error('Barber login failed:', bAuthErr);
    return;
  }
  console.log('6. ✓ Barber logged in:', bAuth.user.email);

  // 7. Check-In with QR
  const { data: checkedInBooking, error: checkInErr } = await barberClient.rpc('check_in_with_qr', {
    p_qr_token: newBooking.qr_token,
  });
  if (checkInErr) {
    console.error('Check-in error:', checkInErr);
    return;
  }
  console.log(`7. ✓ QR Check-in completed! New status: ${checkedInBooking.status}`);

  // 8. Progress to in_progress
  const { data: inProgBooking, error: inProgErr } = await barberClient.rpc('transition_booking_status', {
    p_booking_id: newBooking.id,
    p_to_status: 'in_progress',
  });
  if (inProgErr) {
    console.error('Transition to in_progress error:', inProgErr);
    return;
  }
  console.log(`8. ✓ Service started! New status: ${inProgBooking.status}`);

  // 9. Progress to completed
  const { data: completedBooking, error: compErr } = await barberClient.rpc('transition_booking_status', {
    p_booking_id: newBooking.id,
    p_to_status: 'completed',
  });
  if (compErr) {
    console.error('Transition to completed error:', compErr);
    return;
  }
  console.log(`9. ✓ Service completed! New status: ${completedBooking.status}`);

  console.log('\n=== STAGE 1 FULL FLOW VERIFIED SUCCESSFULLY! ===');
}

testStage1Flow().catch(console.error);
