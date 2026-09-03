-- ============================================================
-- FIX: Allow authenticated users to UPDATE organization_members
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ============================================================

-- Drop the restrictive old policy and replace with permissive one
DROP POLICY IF EXISTS "org_members_update" ON public.organization_members;

-- Allow any authenticated org member to update roles
CREATE POLICY "org_members_update" ON public.organization_members
  FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- Verify it worked
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'organization_members' AND cmd = 'UPDATE';
