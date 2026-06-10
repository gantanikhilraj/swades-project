require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

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

// Initialize Firebase Admin (FCM)
let isFirebaseInitialized = false;
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

if (fs.existsSync(serviceAccountPath)) {
    try {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        isFirebaseInitialized = true;
        console.log('Firebase Admin initialized successfully for FCM.');
    } catch (err) {
        console.error('Failed to initialize Firebase Admin with service account:', err.message);
    }
} else {
    console.warn('WARNING: firebase-service-account.json not found in server directory. FCM push notifications will fall back to logging instead of sending live alerts.');
}

// Helper function to dispatch push notification
async function sendPushNotification(userId, title, body) {
    if (!isFirebaseInitialized) {
        console.log(`[FCM Log] Push skipped (Firebase not initialized). Target User: ${userId} | Title: "${title}" | Body: "${body}"`);
        return;
    }

    try {
        // Fetch user's FCM token from Supabase
        const { data, error } = await supabase
            .from('user_fcm_tokens')
            .select('fcm_token')
            .eq('user_id', userId)
            .single();

        if (error || !data || !data.fcm_token) {
            console.log(`[FCM Log] No registered FCM token found for user: ${userId}`);
            return;
        }

        const message = {
            notification: { title, body },
            token: data.fcm_token
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent FCM notification to user ${userId}:`, response);
    } catch (err) {
        console.error(`Error sending FCM notification to user ${userId}:`, err.message);
    }
}

// JWT Verification Middleware
async function requireAuth(req, res, next) {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: Missing Authorization Bearer token' });
    }

    const token = authHeader.split(' ')[1];
    try {
        const { data: { user }, error } = await supabase.auth.getUser(token);
        if (error || !user) {
            return res.status(401).json({ error: 'Unauthorized: Invalid or expired session' });
        }
        // Attach verified user context to request
        req.user = user;
        next();
    } catch (err) {
        console.error('Auth verification error:', err.message);
        return res.status(401).json({ error: 'Unauthorized: Authentication service error' });
    }
}

// Hourly Slots configuration: 6 AM to 10 PM
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
        const bookingMap = new Map();
        bookings.forEach(b => {
            const shortTime = b.start_time.substring(0, 5); // '06:00:00' -> '06:00'
            bookingMap.set(shortTime, b);
        });

        // Construct 16 hourly slots with booking status
        let slots = SLOT_HOURS.map(hour => {
            const booking = bookingMap.get(hour);
            return {
                start_time: hour,
                status: booking ? 'booked' : 'available',
                booking_id: booking ? booking.id : null,
                user_id: booking ? booking.user_id : null
            };
        });

        // Filter out past slots if the requested date is today
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        const localDateString = `${yyyy}-${mm}-${dd}`;

        if (date === localDateString) {
            const currentHour = today.getHours();
            slots = slots.filter(slot => {
                const slotHour = parseInt(slot.start_time.split(':')[0], 10);
                return slotHour > currentHour;
            });
        }

        return res.json(slots);
    } catch (err) {
        console.error('Error fetching slots:', err.message);
        return res.status(500).json({ error: 'Failed to fetch slots' });
    }
});

// 3. POST /bookings - Book a slot for a user (Protected)
app.post('/bookings', requireAuth, async (req, res) => {
    const userId = req.user.id; // From verified JWT
    const { venue_id, date, start_time } = req.body;

    if (!venue_id || !date || !start_time) {
        return res.status(400).json({ error: 'Missing venue_id, date, or start_time' });
    }

    // Format start_time as HH:MM
    const formattedStartTime = start_time.substring(0, 5);
    if (!SLOT_HOURS.includes(formattedStartTime)) {
        return res.status(400).json({ error: 'Invalid start time slot. Must be between 06:00 and 21:00' });
    }

    // Block booking past slots
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const localDateString = `${yyyy}-${mm}-${dd}`;

    if (date < localDateString) {
        return res.status(400).json({ error: 'Cannot book slots in the past' });
    }

    if (date === localDateString) {
        const currentHour = today.getHours();
        const slotHour = parseInt(formattedStartTime.split(':')[0], 10);
        if (slotHour <= currentHour) {
            return res.status(400).json({ error: 'Cannot book a past slot today' });
        }
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

        const booking = data[0];

        // Fetch venue name asynchronously for notification content
        const { data: venue } = await supabase
            .from('venues')
            .select('name')
            .eq('id', venue_id)
            .single();

        const venueName = venue?.name ?? 'your sports court';

        // Dispatch background push alert
        sendPushNotification(
            userId,
            'Booking Confirmed! ⚡',
            `Your slot at ${venueName} is booked for ${date} at ${formattedStartTime}.`
        );

        return res.status(201).json(booking);
    } catch (err) {
        console.error('Booking error:', err.message);
        return res.status(500).json({ error: 'Failed to create booking' });
    }
});

// 4. GET /users/{id}/bookings - A user's bookings (Protected)
app.get('/users/:id/bookings', requireAuth, async (req, res) => {
    const userId = req.params.id;
    console.log(`[Backend API] GET /users/${userId}/bookings requested with query:`, req.query);

    // Verify that the requested booking ID matches the authenticated user ID
    if (req.user.id !== userId) {
        return res.status(403).json({ error: 'Forbidden: Access denied to other users\' bookings' });
    }

    try {
        let query = supabase
            .from('bookings')
            .select(`
                id,
                user_id,
                booking_date,
                start_time,
                venues!inner (
                    id,
                    name,
                    sport_type,
                    location,
                    image_url
                )
            `)
            .eq('user_id', userId);

        const { date, start_time, sport_type } = req.query;

        if (date) {
            query = query.eq('booking_date', date);
        }
        if (start_time) {
            // Support both '10:00' and '10:00:00' formats
            const formattedTime = start_time.length === 5 ? `${start_time}:00` : start_time;
            query = query.eq('start_time', formattedTime);
        }
        if (sport_type) {
            query = query.eq('venues.sport_type', sport_type);
        }

        const { data, error } = await query
            .order('booking_date', { ascending: true })
            .order('start_time', { ascending: true });

        if (error) throw error;
        console.log(`[Backend API] Query completed. Returning ${data ? data.length : 0} bookings.`);
        return res.json(data || []);
    } catch (err) {
        console.error('Error fetching user bookings:', err.message);
        return res.status(500).json({ error: 'Failed to fetch bookings' });
    }
});

// 5. DELETE /bookings/{id} - Cancel a booking (Protected)
app.delete('/bookings/:id', requireAuth, async (req, res) => {
    const bookingId = req.params.id;
    const userId = req.user.id; // From verified JWT

    try {
        // First check if the booking exists and belongs to the user
        const { data: booking, error: fetchError } = await supabase
            .from('bookings')
            .select('user_id, venue_id, booking_date, start_time')
            .eq('id', bookingId)
            .single();

        if (fetchError || !booking) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        if (booking.user_id !== userId) {
            return res.status(403).json({ error: 'Forbidden: You cannot cancel someone else\'s booking' });
        }

        // Fetch venue details for notification before deleting
        const { data: venue } = await supabase
            .from('venues')
            .select('name')
            .eq('id', booking.venue_id)
            .single();

        const venueName = venue?.name ?? 'your sports court';

        // Perform deletion
        const { error: deleteError } = await supabase
            .from('bookings')
            .delete()
            .eq('id', bookingId);

        if (deleteError) throw deleteError;

        // Dispatch push notification
        sendPushNotification(
            userId,
            'Booking Cancelled ❌',
            `Your slot at ${venueName} on ${booking.booking_date} has been cancelled.`
        );

        return res.json({ message: 'Booking cancelled successfully' });
    } catch (err) {
        console.error('Error cancelling booking:', err.message);
        return res.status(500).json({ error: 'Failed to cancel booking' });
    }
});

// 6. POST /users/fcm-token - Register or update user FCM token (Protected)
app.post('/users/fcm-token', requireAuth, async (req, res) => {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token) {
        return res.status(400).json({ error: 'Missing token in body' });
    }

    try {
        // Upsert the token to map it to the active user ID
        const { error } = await supabase
            .from('user_fcm_tokens')
            .upsert({
                user_id: userId,
                fcm_token: token,
                updated_at: new Date()
            });

        if (error) throw error;

        return res.json({ message: 'FCM Token registered successfully' });
    } catch (err) {
        console.error('Error registering FCM token:', err.message);
        return res.status(500).json({ error: 'Failed to register FCM token' });
    }
});

// 7. DELETE /users/fcm-token - Remove user FCM token on logout (Protected)
app.delete('/users/fcm-token', requireAuth, async (req, res) => {
    const userId = req.user.id;
    try {
        const { error } = await supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId);

        if (error) throw error;

        return res.json({ message: 'FCM Token deleted successfully' });
    } catch (err) {
        console.error('Error deleting FCM token:', err.message);
        return res.status(500).json({ error: 'Failed to delete FCM token' });
    }
});

app.listen(port, () => {
    console.log(`QuickSlot Server listening at http://localhost:${port}`);
});
