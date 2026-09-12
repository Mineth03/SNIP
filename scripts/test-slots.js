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
const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function testSlots() {
  console.log('Testing get_available_slots on live Supabase...');

  // 1. Get Modern Cut salon
  const { data: salon, error: salonErr } = await supabase
    .from('salons')
    .select('id, name, slug')
    .eq('slug', 'the-modern-cut')
    .single();

  if (salonErr || !salon) {
    console.error('Could not find salon:', salonErr);
    return;
  }
  console.log(`Found salon: ${salon.name} (${salon.id})`);

  // 2. Get Service
  const { data: service, error: svcErr } = await supabase
    .from('services')
    .select('id, name, duration_minutes, price')
    .eq('salon_id', salon.id)
    .eq('name', "Men's Haircut")
    .single();

  if (svcErr || !service) {
    console.error('Could not find service:', svcErr);
    return;
  }
  console.log(`Found service: ${service.name} (${service.duration_minutes} mins, LKR ${service.price})`);

  // 3. Get Barber
  const { data: barber, error: bErr } = await supabase
    .from('barbers')
    .select('id, display_name')
    .eq('salon_id', salon.id)
    .single();

  if (bErr || !barber) {
    console.error('Could not find barber:', bErr);
    return;
  }
  console.log(`Found barber: ${barber.display_name} (${barber.id})`);

  // 4. Calculate a future date (2 days from now to avoid Sunday if today is Friday/Sat)
  const targetDate = new Date();
  targetDate.setDate(targetDate.getDate() + 3);
  const dateStr = targetDate.toISOString().slice(0, 10);
  console.log(`Testing slots for date: ${dateStr}`);

  const { data: slots, error: slotErr } = await supabase.rpc('get_available_slots', {
    p_salon_id: salon.id,
    p_service_id: service.id,
    p_barber_id: barber.id,
    p_date: dateStr,
    p_slot_interval_minutes: 30,
    p_buffer_minutes: 0,
  });

  if (slotErr) {
    console.error('Error fetching slots:', slotErr);
    return;
  }

  console.log(`Success! Generated ${slots ? slots.length : 0} available slots for ${barber.display_name}:`);
  if (slots && slots.length > 0) {
    slots.slice(0, 6).forEach(s => {
      console.log(`  • ${s.slot_start} -> ${s.slot_end} (${s.barber_name})`);
    });
    if (slots.length > 6) {
      console.log(`  ... and ${slots.length - 6} more slots`);
    }
  }
}

testSlots().catch(console.error);
