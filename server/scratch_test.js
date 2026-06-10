const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function test() {
  const userId = 'bccf8d5f-b6ec-4b50-92c8-f427931984db';
  
  const { data: all, error: err1 } = await supabase
    .from('bookings')
    .select('id, booking_date, start_time')
    .eq('user_id', userId);
  console.log('All Bookings:', all);

  const { data, error } = await supabase
    .from('bookings')
    .select(`
        id,
        user_id,
        booking_date,
        start_time,
        venues!inner (
            id,
            name,
            sport_type
        )
    `)
    .eq('user_id', userId)
    .eq('booking_date', '2026-06-13');
    
  console.log('Bookings for June 13:', data);
  if (error) console.error('Error:', error);
}

test();
