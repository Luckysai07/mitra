-- ============================================================
-- MITRA — PERMISSIONS & APPROVAL WORKFLOW MIGRATION
-- ============================================================
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ============================================================

-- 0. CLEANUP (Drop new permission tables if partially/incorrectly created previously)
DROP TABLE IF EXISTS public.approval_actions CASCADE;
DROP TABLE IF EXISTS public.permission_overrides CASCADE;
DROP TABLE IF EXISTS public.role_permissions CASCADE;

-- 1. ROLE PERMISSIONS TABLE
-- Maps each role in an org to a set of permission keys.
CREATE TABLE public.role_permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    role_name       TEXT NOT NULL,        -- 'owner','president','treasurer','secretary','member','viewer'
    permission      TEXT NOT NULL,        -- e.g. 'approve_transaction', 'add_transaction'
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by      UUID REFERENCES public.users(id),
    CONSTRAINT role_permissions_org_role_perm_key UNIQUE(org_id, role_name, permission)
);

CREATE INDEX IF NOT EXISTS idx_role_perms_org ON public.role_permissions(org_id);
CREATE INDEX IF NOT EXISTS idx_role_perms_role ON public.role_permissions(org_id, role_name);

-- 2. PERMISSION OVERRIDES TABLE
-- Owner can grant/revoke individual permissions to specific members.
CREATE TABLE public.permission_overrides (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    permission      TEXT NOT NULL,
    is_granted      BOOLEAN NOT NULL DEFAULT true,   -- true = grant, false = revoke
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by      UUID REFERENCES public.users(id),
    CONSTRAINT perm_overrides_org_user_perm_key UNIQUE(org_id, user_id, permission)
);

-- 3. APPROVAL ACTIONS TABLE
-- Logs every approve/reject action on a transaction.
CREATE TABLE public.approval_actions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    transaction_id  UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    action          TEXT NOT NULL,          -- 'approved' or 'rejected'
    reason          TEXT,
    performed_by    UUID NOT NULL REFERENCES public.users(id),
    performed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_approval_actions_txn ON public.approval_actions(transaction_id);

-- 4. ADD APPROVAL COLUMNS TO TRANSACTIONS
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved';
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.users(id);
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Change default approval status for future inserted transactions to 'pending'
ALTER TABLE public.transactions ALTER COLUMN approval_status SET DEFAULT 'pending';

-- ============================================================
-- AUTO-SEED DEFAULT PERMISSIONS WHEN AN ORGANIZATION IS CREATED
-- ============================================================

CREATE OR REPLACE FUNCTION public.seed_role_permissions()
RETURNS TRIGGER AS $$
BEGIN
    -- Owner: ALL permissions
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'owner', 'approve_transaction'),
        (NEW.id, 'owner', 'add_transaction'),
        (NEW.id, 'owner', 'edit_transaction'),
        (NEW.id, 'owner', 'void_transaction'),
        (NEW.id, 'owner', 'manage_members'),
        (NEW.id, 'owner', 'manage_permissions'),
        (NEW.id, 'owner', 'edit_org_settings'),
        (NEW.id, 'owner', 'view_audit_logs'),
        (NEW.id, 'owner', 'view_reports'),
        (NEW.id, 'owner', 'export_data')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    -- President: approve, manage members, view audit & reports
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'president', 'approve_transaction'),
        (NEW.id, 'president', 'add_transaction'),
        (NEW.id, 'president', 'edit_transaction'),
        (NEW.id, 'president', 'manage_members'),
        (NEW.id, 'president', 'view_audit_logs'),
        (NEW.id, 'president', 'view_reports'),
        (NEW.id, 'president', 'export_data')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    -- Treasurer: add/edit transactions, view reports & export
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'treasurer', 'add_transaction'),
        (NEW.id, 'treasurer', 'edit_transaction'),
        (NEW.id, 'treasurer', 'view_reports'),
        (NEW.id, 'treasurer', 'export_data')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    -- Secretary: manage members, view reports
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'secretary', 'add_transaction'),
        (NEW.id, 'secretary', 'manage_members'),
        (NEW.id, 'secretary', 'view_reports')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    -- Member: can add transactions (they go to pending)
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'member', 'add_transaction'),
        (NEW.id, 'member', 'view_reports')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    -- Viewer: read-only dashboard
    INSERT INTO public.role_permissions (org_id, role_name, permission)
    VALUES
        (NEW.id, 'viewer', 'view_reports')
    ON CONFLICT (org_id, role_name, permission) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_organization_seed_permissions ON public.organizations;
CREATE TRIGGER on_organization_seed_permissions
    AFTER INSERT ON public.organizations
    FOR EACH ROW EXECUTE FUNCTION public.seed_role_permissions();

-- ============================================================
-- ROW LEVEL SECURITY FOR NEW TABLES
-- ============================================================

ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permission_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_actions ENABLE ROW LEVEL SECURITY;

-- Role Permissions Policies
DROP POLICY IF EXISTS "role_perms_select" ON public.role_permissions;
DROP POLICY IF EXISTS "role_perms_insert" ON public.role_permissions;
DROP POLICY IF EXISTS "role_perms_update" ON public.role_permissions;
DROP POLICY IF EXISTS "role_perms_delete" ON public.role_permissions;

CREATE POLICY "role_perms_select" ON public.role_permissions FOR SELECT USING (true);
CREATE POLICY "role_perms_insert" ON public.role_permissions FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "role_perms_update" ON public.role_permissions FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "role_perms_delete" ON public.role_permissions FOR DELETE USING (auth.role() = 'authenticated');

-- Permission Overrides Policies
DROP POLICY IF EXISTS "perm_overrides_select" ON public.permission_overrides;
DROP POLICY IF EXISTS "perm_overrides_insert" ON public.permission_overrides;
DROP POLICY IF EXISTS "perm_overrides_update" ON public.permission_overrides;
DROP POLICY IF EXISTS "perm_overrides_delete" ON public.permission_overrides;

CREATE POLICY "perm_overrides_select" ON public.permission_overrides FOR SELECT USING (true);
CREATE POLICY "perm_overrides_insert" ON public.permission_overrides FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "perm_overrides_update" ON public.permission_overrides FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "perm_overrides_delete" ON public.permission_overrides FOR DELETE USING (auth.role() = 'authenticated');

-- Approval Actions Policies
DROP POLICY IF EXISTS "approval_actions_select" ON public.approval_actions;
DROP POLICY IF EXISTS "approval_actions_insert" ON public.approval_actions;

CREATE POLICY "approval_actions_select" ON public.approval_actions FOR SELECT USING (true);
CREATE POLICY "approval_actions_insert" ON public.approval_actions FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- SEED PERMISSIONS FOR EXISTING ORGANIZATIONS (one-time backfill)
-- ============================================================
DO $$
DECLARE
    target_org RECORD;
BEGIN
    FOR target_org IN SELECT id FROM public.organizations LOOP
        -- Owner
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'owner', 'approve_transaction'), (target_org.id, 'owner', 'add_transaction'),
            (target_org.id, 'owner', 'edit_transaction'), (target_org.id, 'owner', 'void_transaction'),
            (target_org.id, 'owner', 'manage_members'), (target_org.id, 'owner', 'manage_permissions'),
            (target_org.id, 'owner', 'edit_org_settings'), (target_org.id, 'owner', 'view_audit_logs'),
            (target_org.id, 'owner', 'view_reports'), (target_org.id, 'owner', 'export_data')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;

        -- President
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'president', 'approve_transaction'), (target_org.id, 'president', 'add_transaction'),
            (target_org.id, 'president', 'edit_transaction'), (target_org.id, 'president', 'manage_members'),
            (target_org.id, 'president', 'view_audit_logs'), (target_org.id, 'president', 'view_reports'),
            (target_org.id, 'president', 'export_data')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;

        -- Treasurer
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'treasurer', 'add_transaction'), (target_org.id, 'treasurer', 'edit_transaction'),
            (target_org.id, 'treasurer', 'view_reports'), (target_org.id, 'treasurer', 'export_data')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;

        -- Secretary
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'secretary', 'add_transaction'), (target_org.id, 'secretary', 'manage_members'),
            (target_org.id, 'secretary', 'view_reports')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;

        -- Member
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'member', 'add_transaction'), (target_org.id, 'member', 'view_reports')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;

        -- Viewer
        INSERT INTO public.role_permissions (org_id, role_name, permission) VALUES
            (target_org.id, 'viewer', 'view_reports')
        ON CONFLICT (org_id, role_name, permission) DO NOTHING;
    END LOOP;
END;
$$;

