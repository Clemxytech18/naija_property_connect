-- Seed Data for Naija Property Connect

-- Variables
-- Landlord ID: b78e31a3-3869-49dc-8203-3bdea7577c42
-- Tenant ID: c2c0d9f0-c855-4dcf-b3bf-80aa2422025d

-- 0. Ensure Users Exist in public.users
-- We invoke these inserts to ensure the foreign key constraints in 'properties' and 'bookings' are met.
-- IMPORTANT: These IDs must exist in auth.users first.
INSERT INTO public.users (id, email, full_name, phone, role, created_at)
VALUES 
  ('b78e31a3-3869-49dc-8203-3bdea7577c42', 'landlord@example.com', 'Chief Landlord', '+2348000000001', 'landlord', NOW()),
  ('c2c0d9f0-c855-4dcf-b3bf-80aa2422025d', 'tenant@example.com', 'Emeka Tenant', '+2348000000002', 'tenant', NOW())
ON CONFLICT (id) DO UPDATE 
SET 
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name; -- Update role/name just in case

-- 1. Insert Properties (Assigned to Landlord)
INSERT INTO public.properties (id, owner_id, title, description, price, location, type, images, bedrooms, bathrooms, features, agent_fee, agreement_fee, caution_fee, created_at)
VALUES 
  (
    uuid_generate_v4(), 
    'b78e31a3-3869-49dc-8203-3bdea7577c42', 
    'Modern 3 Bedroom Apartment in Ikoyi', 
    'Luxurious 3-bedroom apartment located in the accessible area of Ikoyi. Features include a swimming pool, gym, 24/7 power supply, and top-tier security. Perfect for expatriates and executives.', 
    8500000, 
    'Ikoyi, Lagos', 
    'Apartment', 
    ARRAY['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
    3, 
    4, 
    ARRAY['Swimming Pool', 'Gym', '24/7 Power', 'Security', 'Elevator'], 
    850000, 
    425000, 
    500000, 
    NOW()
  ),
  (
    uuid_generate_v4(), 
    'b78e31a3-3869-49dc-8203-3bdea7577c42', 
    'Cozy 2 Bedroom Flat in Yaba', 
    'A newly built 2-bedroom flat in a quiet neighborhood in Yaba. Close to Unilag and major tech hubs. Great for young professionals.', 
    2500000, 
    'Yaba, Lagos', 
    'Apartment', 
    ARRAY['https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', 'https://images.unsplash.com/photo-1502005229766-52835791e80d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
    2, 
    2, 
    ARRAY['Parking', 'Water Treatment', 'Fenced'], 
    250000, 
    125000, 
    0,
    NOW() - INTERVAL '2 days'
  ),
  (
    uuid_generate_v4(), 
    'b78e31a3-3869-49dc-8203-3bdea7577c42', 
    'Luxury 5 Bedroom Detached Duplex', 
    'Exquisite 5-bedroom detached duplex with a boys quarter in Lekki Phase 1. High ceilings, marble floors, fitted kitchen, and cinema room.', 
    12000000, 
    'Lekki Phase 1, Lagos', 
    'House', 
    ARRAY['https://images.unsplash.com/photo-1600596542815-27b88e5c1695?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80', 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
    5, 
    6, 
    ARRAY['Cinema', 'Fitted Kitchen', 'Boys Quarter', 'Smart Home'], 
    1000000, 
    500000, 
    0,
    NOW() - INTERVAL '5 days'
  ),
  (
    uuid_generate_v4(), 
    'b78e31a3-3869-49dc-8203-3bdea7577c42', 
    'Serviced Office Space in Victoria Island', 
    'Premium open-plan office space in the heart of VI. Includes conference room access, high-speed internet, and reception services.', 
    5000000, 
    'Victoria Island, Lagos', 
    'Office', 
    ARRAY['https://images.unsplash.com/photo-1497215728101-856f4ea42174?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
    0, 
    0, 
    ARRAY['Internet', 'Conference Room', 'Reception', 'Elevator'], 
    0, 
    0, 
    0,
    NOW() - INTERVAL '10 days'
  ),
  (
    uuid_generate_v4(), 
    'b78e31a3-3869-49dc-8203-3bdea7577c42', 
    'Affordable Self Contain in Ikorodu', 
    'Clean and spacious self-contain apartment in Ikorodu. Tiled floors, running water, and good electricity.', 
    350000, 
    'Ikorodu, Lagos', 
    'Apartment', 
    ARRAY['https://images.unsplash.com/photo-1596178065887-1198b6148b2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'],
    1, 
    1, 
    ARRAY['Running Water', 'Tiled Floors'], 
    35000, 
    17500, 
    0,
    NOW() - INTERVAL '12 days'
  );

-- 2. Insert Bookings (Tenant booking Landlord's properties)
-- We need to dynamically select the property IDs we just inserted. 
-- For simplicity in this script, we'll pick the most recently inserted properties for this landlord.

INSERT INTO public.bookings (id, property_id, user_id, date, status, created_at)
SELECT 
  uuid_generate_v4(), 
  id, 
  'c2c0d9f0-c855-4dcf-b3bf-80aa2422025d', -- Tenant ID
  NOW() + INTERVAL '2 days', 
  'pending', 
  NOW()
FROM public.properties 
WHERE owner_id = 'b78e31a3-3869-49dc-8203-3bdea7577c42' 
LIMIT 1;

INSERT INTO public.bookings (id, property_id, user_id, date, status, created_at)
SELECT 
  uuid_generate_v4(), 
  id, 
  'c2c0d9f0-c855-4dcf-b3bf-80aa2422025d', -- Tenant ID
  NOW() + INTERVAL '5 days', 
  'confirmed', 
  NOW()
FROM public.properties 
WHERE owner_id = 'b78e31a3-3869-49dc-8203-3bdea7577c42' 
OFFSET 1 LIMIT 1;
