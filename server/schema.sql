-- Drop existing tables if they exist (clean setup)
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS venues CASCADE;

-- Create Venues table
CREATE TABLE venues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    sport_type TEXT NOT NULL,
    location TEXT NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create Bookings table with UNIQUE constraint
CREATE TABLE bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    venue_id UUID REFERENCES venues(id) ON DELETE CASCADE NOT NULL,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_venue_slot UNIQUE (venue_id, booking_date, start_time)
);

-- Seed Initial Venues
INSERT INTO venues (name, sport_type, location, image_url) VALUES
('Greenfield Badminton Club', 'Badminton', 'Sector 62, Noida', 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=500&auto=format&fit=crop&q=60'),
('Apex Turf Arena', 'Football', 'Indiranagar, Bengaluru', 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500&auto=format&fit=crop&q=60'),
('Smash & Volley Tennis Center', 'Tennis', 'Bandra West, Mumbai', 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=500&auto=format&fit=crop&q=60'),
('Primal Basketball Court', 'Basketball', 'Gachibowli, Hyderabad', 'https://images.unsplash.com/photo-1544698310-74ea9d1c8258?w=500&auto=format&fit=crop&q=60');

-- Create user_fcm_tokens table
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    user_id TEXT PRIMARY KEY,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

