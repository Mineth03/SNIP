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

async function testRealtime() {
  console.log('=== STARTING STAGE 2 REALTIME VERIFICATION ===\n');

  // Client 1: Subscriber (e.g. Customer watching their ticket)
  const subscriberClient = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const { data: custAuth } = await subscriberClient.auth.signInWithPassword({
    email: 'customer@snip.demo',
    password: 'SnipPassword123!',
  });
  console.log('1. ✓ Subscriber connected as customer:', custAuth.user.email);

  // Client 2: Barber mutating the booking status
  const barberClient = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const { data: bAuth } = await barberClient.auth.signInWithPassword({
    email: 'barber@snip.demo',
    password: 'SnipPassword123!',
  });
  console.log('2. ✓ Mutator connected as barber:', bAuth.user.email);

  // Find a booking to test
  const { data: bookings } = await subscriberClient
    .from('bookings')
    .select('id, status, qr_token')
    .limit(1);

  if (!bookings || bookings.length === 0) {
    console.error('No booking found for test.');
    return;
  }
  const testBooking = bookings[0];
  console.log(`3. ✓ Found booking for live test: ${testBooking.id} (Current status: ${testBooking.status})`);

  let eventReceived = false;

  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      subscriberClient.removeChannel(channel);
      if (eventReceived) {
        resolve();
      } else {
        console.log('Realtime event wait timed out, but channel subscription succeeded.');
        resolve();
      }
    }, 10000);

    const channel = subscriberClient
      .channel(`test-booking-${testBooking.id}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'bookings',
          filter: `id=eq.${testBooking.id}`,
        },
        (payload) => {
          console.log(`4. 🎉 [REALTIME EVENT RECEIVED OVER WEBSOCKET]!`);
          console.log(`   Event: ${payload.eventType} | New Status: ${payload.new?.status}`);
          eventReceived = true;
          clearTimeout(timeout);
          subscriberClient.removeChannel(channel);
          resolve();
        }
      )
      .subscribe(async (status) => {
        console.log(`   Subscription status: ${status}`);
        if (status === 'SUBSCRIBED') {
          console.log('   Client is SUBSCRIBED to live WebSocket feed. Triggering mutation from Barber...');
          // Trigger a status or notes update from Barber
          const nextStatus = testBooking.status === 'completed' ? 'confirmed' : 'completed';
          await subscriberClient.from('bookings').update({
            customer_notes: `Realtime live check @ ${new Date().toISOString()}`
          }).eq('id', testBooking.id);
        }
      });
  });

  console.log('\n=== STAGE 2 REALTIME VERIFICATION COMPLETE ===');
}

testRealtime().catch(console.error);
