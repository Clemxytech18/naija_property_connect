-- Enable RLS on bookings table if not already enabled
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- DROP existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Agents can update bookings for their properties" ON bookings;

-- User Policies (Tenant)
-- Allow users to view their own bookings
CREATE POLICY "Users can view own bookings" ON bookings
    FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to update their own bookings (e.g. to CANCEL)
CREATE POLICY "Users can update own bookings" ON bookings
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Agent Policies (Landlord)
-- Allow agents to view bookings for their properties
CREATE POLICY "Agents can view bookings for their properties" ON bookings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties
            WHERE properties.id = bookings.property_id
            AND properties.owner_id = auth.uid()
        )
    );

-- Allow agents to update bookings for their properties (e.g. CONFIRM/DECLINE)
CREATE POLICY "Agents can update bookings for their properties" ON bookings
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.properties
            WHERE properties.id = bookings.property_id
            AND properties.owner_id = auth.uid()
        )
    );

-- Allow creating bookings (Tenant)
CREATE POLICY "Users can insert bookings" ON bookings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);
