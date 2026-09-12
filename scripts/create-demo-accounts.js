const fs = require('fs');
const path = require('path');

// 1. Read environment variables from apps/web/.env.local
const envPath = path.resolve(__dirname, '../apps/web/.env.local');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;
  const eqIdx = trimmed.indexOf('=');
  if (eqIdx !== -1) {
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim();
    env[key] = val;
  }
});

const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const { createClient } = require(path.resolve(__dirname, '../apps/web/node_modules/@supabase/supabase-js'));
const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const DEMO_USERS = [
  {
    role: 'customer',
    email: 'customer@snip.demo',
    password: 'SnipPassword123!',
    fullName: 'James Perera',
    phone: '+94 77 123 4567',
  },
  {
    role: 'salon_owner',
    email: 'owner@snip.demo',
    password: 'SnipPassword123!',
    fullName: 'Alex Fernando',
    phone: '+94 77 234 5678',
  },
  {
    role: 'barber',
    email: 'barber@snip.demo',
    password: 'SnipPassword123!',
    fullName: 'Kamal Perera',
    phone: '+94 77 345 6789',
  },
  {
    role: 'admin',
    email: 'admin@snip.demo',
    password: 'SnipPassword123!',
    fullName: 'Admin User',
    phone: '+94 77 456 7890',
  },
];

async function main() {
  console.log('Connecting to Supabase at:', supabaseUrl);
  const createdProfiles = {};

  for (const user of DEMO_USERS) {
    console.log(`\nProcessing ${user.role} (${user.email})...`);

    // 1. Check if user already exists in auth.users
    const { data: listData, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error('Failed to list users:', listError);
      process.exit(1);
    }

    let authUser = listData.users.find(u => u.email === user.email);

    if (!authUser) {
      console.log(`Creating auth user ${user.email}...`);
      const { data: createData, error: createError } = await supabase.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true,
        user_metadata: {
          full_name: user.fullName,
          role: user.role,
          phone: user.phone,
        },
      });

      if (createError) {
        console.error(`Error creating ${user.email}:`, createError);
        continue;
      }
      authUser = createData.user;
    } else {
      console.log(`User ${user.email} already exists (${authUser.id}). Updating password and metadata...`);
      await supabase.auth.admin.updateUserById(authUser.id, {
        password: user.password,
        email_confirm: true,
        user_metadata: {
          full_name: user.fullName,
          role: user.role,
          phone: user.phone,
        },
      });
    }

    createdProfiles[user.role] = { ...user, id: authUser.id };

    // 2. Ensure public.profiles has correct role, full_name, and phone
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert({
        id: authUser.id,
        role: user.role,
        full_name: user.fullName,
        email: user.email,
        phone: user.phone,
      }, { onConflict: 'id' });

    if (profileError) {
      console.error(`Error upserting profile for ${user.email}:`, profileError);
    } else {
      console.log(`✓ Profile updated with role: ${user.role}`);
    }
  }

  // 3. Create demo Salon for the Salon Owner ("The Modern Cut")
  const owner = createdProfiles['salon_owner'];
  const customer = createdProfiles['customer'];
  const barber = createdProfiles['barber'];

  if (owner) {
    console.log('\nSetting up demo salon "The Modern Cut"...');

    const salonData = {
      owner_id: owner.id,
      name: 'The Modern Cut',
      slug: 'the-modern-cut',
      description: 'Premium modern haircuts, styling, and beard trims in Colombo 05.',
      email: 'themoderncut@snip.demo',
      phone: '+94 11 234 5678',
      address: '42 Galle Road, Colombo 05',
      city: 'Colombo 05',
      latitude: 6.8912,
      longitude: 79.8601,
      verification_status: 'verified',
      is_active: true,
      opening_hours: {
        monday: { open: '09:00', close: '20:00' },
        tuesday: { open: '09:00', close: '20:00' },
        wednesday: { open: '09:00', close: '20:00' },
        thursday: { open: '09:00', close: '20:00' },
        friday: { open: '09:00', close: '21:00' },
        saturday: { open: '09:00', close: '21:00' },
        sunday: { open: '10:00', close: '18:00' },
      },
    };

    // Upsert salon by slug
    let { data: existingSalons } = await supabase.from('salons').select('id').eq('slug', salonData.slug);
    let salonId;
    if (existingSalons && existingSalons.length > 0) {
      salonId = existingSalons[0].id;
      await supabase.from('salons').update(salonData).eq('id', salonId);
    } else {
      const { data: newSalon, error: salonErr } = await supabase.from('salons').insert(salonData).select().single();
      if (salonErr) {
        console.error('Error creating salon:', salonErr);
      } else {
        salonId = newSalon.id;
      }
    }
    console.log('✓ Salon ready (ID:', salonId, ')');

    if (salonId) {
      // Create Services matching the design mockup
      const demoServices = [
        { name: "Men's Haircut", description: 'Wash, cut, and style', category: 'hair', price: 1500, duration_minutes: 30 },
        { name: 'Beard Trim', description: 'Beard shaping and grooming', category: 'beard', price: 1000, duration_minutes: 20 },
        { name: 'Hair Wash & Blow Dry', description: 'Deep cleanse with scalp massage', category: 'hair', price: 800, duration_minutes: 20 },
        { name: 'Hair Colouring', description: 'Full or touch-up professional color', category: 'color', price: 3500, duration_minutes: 60 },
        { name: 'Deep Cleansing Facial', description: 'Rejuvenating skin care session', category: 'facial', price: 2800, duration_minutes: 45 },
      ];

      for (const s of demoServices) {
        const { data: existingSvc } = await supabase.from('services').select('id').eq('salon_id', salonId).eq('name', s.name);
        if (!existingSvc || existingSvc.length === 0) {
          await supabase.from('services').insert({ ...s, salon_id: salonId, is_active: true });
        }
      }
      console.log('✓ Services registered');

      // Create Barber entry for "Kamal Perera"
      let barberId;
      if (barber) {
        const { data: existingBarber } = await supabase.from('barbers').select('id').eq('salon_id', salonId).eq('display_name', 'Kamal Perera');
        if (existingBarber && existingBarber.length > 0) {
          barberId = existingBarber[0].id;
        } else {
          const { data: newBarber, error: bErr } = await supabase.from('barbers').insert({
            salon_id: salonId,
            profile_id: barber.id,
            display_name: 'Kamal Perera',
            bio: 'Master stylist with over 8 years experience in fades, scissor work, and beard design.',
            specializations: ['Fade Cuts', 'Beard Styling', 'Scissor Craft'],
            is_active: true,
          }).select().single();
          if (newBarber) barberId = newBarber.id;
        }
        console.log('✓ Barber Kamal registered (ID:', barberId, ')');

        // Create weekly schedule for Kamal
        if (barberId) {
          const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
          for (const d of days) {
            const { data: exSched } = await supabase.from('barber_schedules').select('id').eq('barber_id', barberId).eq('day_of_week', d);
            if (!exSched || exSched.length === 0) {
              await supabase.from('barber_schedules').insert({
                barber_id: barberId,
                day_of_week: d,
                start_time: '09:00:00',
                end_time: '19:00:00',
                is_working: d !== 'sunday',
              });
            }
          }
          console.log('✓ Barber schedule set (Mon-Sat 9AM-7PM)');
        }
      }

      // Create a demo booking for James Perera (matching the QR ticket in the mockup: SNIP784629)
      if (customer && barberId) {
        const { data: svcList } = await supabase.from('services').select('id, price').eq('salon_id', salonId).eq('name', "Men's Haircut").limit(1);
        const haircutSvc = svcList && svcList[0];
        if (haircutSvc) {
          const { data: exBooking } = await supabase.from('bookings').select('id').eq('qr_token', 'SNIP784629');
          if (!exBooking || exBooking.length === 0) {
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(10, 0, 0, 0);
            const endTime = new Date(tomorrow);
            endTime.setMinutes(endTime.getMinutes() + 30);

            const demoQrToken = '78462900-0000-4000-8000-000000784629';
            const { error: bkgErr } = await supabase.from('bookings').insert({
              salon_id: salonId,
              customer_id: customer.id,
              service_id: haircutSvc.id,
              barber_id: barberId,
              appointment_start: tomorrow.toISOString(),
              appointment_end: endTime.toISOString(),
              status: 'confirmed',
              price: haircutSvc.price,
              qr_token: demoQrToken,
            });
            if (bkgErr) {
              console.log('Notice on demo booking insert:', bkgErr.message);
            } else {
              console.log('✓ Demo booking created for James Perera (QR Token:', demoQrToken, ')');
            }
          }
        }
      }
    }
  }

  // 4. Create the root DEMO_ACCOUNTS.txt file
  const fileContent = `================================================================================
SNIP - SMART SALON BOOKING & MANAGEMENT SYSTEM
DEMO CREDENTIALS & TEST ACCOUNTS
================================================================================

All demo accounts have been pre-created and verified in Supabase Auth.
Password for ALL demo accounts: SnipPassword123!

--------------------------------------------------------------------------------
1. CUSTOMER ACCOUNT (Client Portal & Mobile Booking)
--------------------------------------------------------------------------------
Email:     customer@snip.demo
Password:  SnipPassword123!
Name:      James Perera
Phone:     +94 77 123 4567
Role:      customer

Features:
• Web portal:    http://localhost:3000/customer
• Explore:       http://localhost:3000/explore
• Salon Booking: http://localhost:3000/salons/the-modern-cut/book
• Mobile app:    Log in to test Customer Home, Salon Details, & QR Ticket
• Demo Ticket:   Upcoming appointment at "The Modern Cut" with QR Code (SNIP784629)

--------------------------------------------------------------------------------
2. SALON OWNER ACCOUNT (Salon Management Portal)
--------------------------------------------------------------------------------
Email:     owner@snip.demo
Password:  SnipPassword123!
Name:      Alex Fernando
Phone:     +94 77 234 5678
Role:      salon_owner

Features:
• Web Dashboard: http://localhost:3000/owner
• Bookings:      http://localhost:3000/owner/bookings
• Calendar:      http://localhost:3000/owner/calendar
• Staff/Barbers: http://localhost:3000/owner/staff
• Services:      http://localhost:3000/owner/services
• Walk-in Desk:  http://localhost:3000/owner/walk-in
• QR Check-In:   http://localhost:3000/owner/qr
• Mobile app:    Log in to view Owner Dashboard with live KPIs & appointments

--------------------------------------------------------------------------------
3. BARBER / STYLIST ACCOUNT (Barber Schedule & Queue)
--------------------------------------------------------------------------------
Email:     barber@snip.demo
Password:  SnipPassword123!
Name:      Kamal Perera
Phone:     +94 77 345 6789
Role:      barber

Features:
• Web Portal:    http://localhost:3000/barber
• Appointments:  http://localhost:3000/barber/appointments
• Schedule:      http://localhost:3000/barber/schedule
• QR Scanner:    http://localhost:3000/barber/scan
• Mobile app:    Log in to view Barber Queue, "Start Service", & Scan QR

--------------------------------------------------------------------------------
4. ADMIN ACCOUNT (Super Admin Platform Overview)
--------------------------------------------------------------------------------
Email:     admin@snip.demo
Password:  SnipPassword123!
Name:      Admin User
Phone:     +94 77 456 7890
Role:      admin

Features:
• Web Overview:  http://localhost:3000/admin
• User Directory:http://localhost:3000/admin/users
• Salons list:   http://localhost:3000/admin/salons
• Verification:  http://localhost:3000/admin/verification (verify/reject salons)
• Reports:       http://localhost:3000/admin/reports

================================================================================
SUPABASE DETAILS
================================================================================
Project URL: https://vjvxfpitlxxfnpvxmkse.supabase.co
Region:      South Asia (Mumbai)

================================================================================
`;

  const outputPath = path.resolve(__dirname, '../DEMO_ACCOUNTS.txt');
  fs.writeFileSync(outputPath, fileContent, 'utf8');
  console.log(`\n=======================================================`);
  console.log(`✓ Demo accounts file written to: DEMO_ACCOUNTS.txt`);
  console.log(`=======================================================\n`);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
