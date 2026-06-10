require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Supabase Client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('YOUR_SUPABASE') || supabaseKey.includes('YOUR_SUPABASE')) {
    console.warn('WARNING: Supabase URL or Key is missing or using placeholder values. Please check your .env file.');
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Hourly Slots configuration: 6 AM to 10 PM (slots start hourly from 06:00 to 21:00)
const SLOT_HOURS = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
];

// 1. GET /venues - List venues
app.get('/venues', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('venues')
            .select('*')
            .order('name');
        
        if (error) throw error;
        return res.json(data || []);
    } catch (err) {
        console.error('Error fetching venues:', err.message);
        return res.status(500).json({ error: 'Failed to fetch venues' });
    }
});

// 2. GET /venues/{id}/slots?date=YYYY-MM-DD - Slots for a date, with status
app.get('/venues/:id/slots', async (req, res) => {
    const venueId = req.params.id;
    const { date } = req.query;

    if (!date) {
        return res.status(400).json({ error: 'Missing date parameter' });
    }

    try {
        // Fetch existing bookings for this venue and date
        const { data: bookings, error } = await supabase
            .from('bookings')
            .select('id, user_id, start_time')
            .eq('venue_id', venueId)
            .eq('booking_date', date);

        if (error) throw error;

        // Map bookings by start_time for quick lookup
        // start_time in postgres might return as '06:00:00' or '06:00'
        const bookingMap = new Map();
        bookings.forEach(b => {
            const shortTime = b.start_time.substring(0, 5); // '06:00:00' -> '06:00'
            bookingMap.set(shortTime, b);
        });

        // Construct 16 hourly slots with booking status
        const slots = SLOT_HOURS.map(hour => {
            const booking = bookingMap.get(hour);
            return {
                start_time: hour,
                status: booking ? 'booked' : 'available',
                booking_id: booking ? booking.id : null,
                user_id: booking ? booking.user_id : null
            };
        });

        return res.json(slots);
    } catch (err) {
        console.error('Error fetching slots:', err.message);
        return res.status(500).json({ error: 'Failed to fetch slots' });
    }
});

// 3. POST /bookings - Book a slot for a user
app.post('/bookings', async (req, res) => {
    const userId = req.headers['x-user-id'];
    const { venue_id, date, start_time } = req.body;

    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing X-User-Id header' });
    }
    if (!venue_id || !date || !start_time) {
        return res.status(400).json({ error: 'Missing venue_id, date, or start_time' });
    }

    // Format start_time as HH:MM
    const formattedStartTime = start_time.substring(0, 5);
    if (!SLOT_HOURS.includes(formattedStartTime)) {
        return res.status(400).json({ error: 'Invalid start time slot. Must be between 06:00 and 21:00' });
    }

    try {
        const { data, error } = await supabase
            .from('bookings')
            .insert([
                {
                    user_id: userId,
                    venue_id: venue_id,
                    booking_date: date,
                    start_time: `${formattedStartTime}:00`
                }
            ])
            .select();

        if (error) {
            // Check for Postgres Unique Constraint Violation (Error Code 23505)
            if (error.code === '23505') {
                return res.status(409).json({ error: 'Slot already booked' });
            }
            throw error;
        }

        return res.status(201).json(data[0]);
    } catch (err) {
        console.error('Booking error:', err.message);
        return res.status(500).json({ error: 'Failed to create booking' });
    }
});

// 4. GET /users/{id}/bookings - A user's bookings (joining with venue details)
app.get('/users/:id/bookings', async (req, res) => {
    const userId = req.params.id;

    try {
        // Fetch bookings for this user and join with venue details
        const { data, error } = await supabase
            .from('bookings')
            .select(`
                id,
                user_id,
                booking_date,
                start_time,
                venues (
                    id,
                    name,
                    sport_type,
                    location,
                    image_url
                )
            `)
            .eq('user_id', userId)
            .order('booking_date', { ascending: true })
            .order('start_time', { ascending: true });

        if (error) throw error;
        return res.json(data || []);
    } catch (err) {
        console.error('Error fetching user bookings:', err.message);
        return res.status(500).json({ error: 'Failed to fetch bookings' });
    }
});

// 5. DELETE /bookings/{id} - Cancel a booking
app.delete('/bookings/:id', async (req, res) => {
    const bookingId = req.params.id;
    const userId = req.headers['x-user-id'];

    if (!userId) {
        return res.status(401).json({ error: 'Unauthorized: Missing X-User-Id header' });
    }

    try {
        // First check if the booking exists and belongs to the user
        const { data: booking, error: fetchError } = await supabase
            .from('bookings')
            .select('user_id')
            .eq('id', bookingId)
            .single();

        if (fetchError || !booking) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        if (booking.user_id !== userId) {
            return res.status(403).json({ error: 'Forbidden: You cannot cancel someone else\'s booking' });
        }

        // Perform deletion
        const { error: deleteError } = await supabase
            .from('bookings')
            .delete()
            .eq('id', bookingId);

        if (deleteError) throw deleteError;

        return res.json({ message: 'Booking cancelled successfully' });
    } catch (err) {
        console.error('Error cancelling booking:', err.message);
        return res.status(500).json({ error: 'Failed to cancel booking' });
    }
});

app.listen(port, () => {
    console.log(`QuickSlot Server listening at http://localhost:${port}`);
});
