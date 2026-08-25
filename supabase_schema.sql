-- ============================================================
-- MITRA DIGITAL BOOK — SUPABASE MIGRATION SCRIPT
-- ============================================================
-- Copy and run this script in the Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ============================================================

-- 1. EXTENSIONS & TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE permission_key AS ENUM (
    'view_transactions',
    'create_transactions',
    'edit_transactions',
    'delete_transactions',
    'approve_transactions',
    'view_receipts',
    'upload_receipts',
    'generate_receipts',
    'manage_members',
    'manage_roles',
    'manage_events',
    'manage_tasks',
    'view_reports',
    'export_reports',
    'manage_budgets',
    'manage_announcements',
    'manage_organization',
    'manage_settings',
    'close_period',
    'view_audit_logs',
    'manage_accounts',
    'manage_categories',
    'manage_transparency'
);

-- 2. USERS TABLE
CREATE TABLE public.users (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       TEXT NOT NULL,
    display_name    TEXT,
    email           TEXT,
    phone           TEXT,
    avatar_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);

-- Handle new auth user registration automatically
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. ORGANIZATIONS TABLE
CREATE TABLE public.organizations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    slug            TEXT UNIQUE NOT NULL,
    org_type        TEXT NOT NULL DEFAULT 'general',
    description     TEXT,
    location        TEXT,
    season_year     TEXT,
    logo_url        TEXT,
    contact_email   TEXT,
    contact_phone   TEXT,
    currency_code   TEXT NOT NULL DEFAULT 'INR',
    currency_symbol TEXT NOT NULL DEFAULT '₹',
    locale          TEXT NOT NULL DEFAULT 'en_IN',
    join_code       TEXT UNIQUE NOT NULL,
    join_qr_data    TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID NOT NULL REFERENCES public.users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_organizations_join_code ON public.organizations(join_code);

-- 4. ROLES & PERMISSIONS
CREATE TABLE public.roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    display_name    TEXT NOT NULL,
    description     TEXT,
    is_system       BOOLEAN NOT NULL DEFAULT false,
    priority        INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(org_id, name)
);

CREATE TABLE public.role_permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id         UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    permission      permission_key NOT NULL,
    UNIQUE(role_id, permission)
);

-- 5. ORGANIZATION MEMBERS
CREATE TABLE public.organization_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role_id         UUID NOT NULL REFERENCES public.roles(id),
    status          TEXT NOT NULL DEFAULT 'active',
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(org_id, user_id)
);

CREATE INDEX idx_org_members_user ON public.organization_members(user_id);
CREATE INDEX idx_org_members_org ON public.organization_members(org_id);

-- 6. FESTIVAL PERIODS
CREATE TABLE public.festival_periods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    opening_balance_paise BIGINT NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'active',
    closed_at       TIMESTAMPTZ,
    closed_by       UUID REFERENCES public.users(id),
    closing_report_url TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. FINANCIAL ACCOUNTS
CREATE TABLE public.financial_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    account_type    TEXT NOT NULL DEFAULT 'cash',
    description     TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. TRANSACTION CATEGORIES
CREATE TABLE public.transaction_categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,
    icon            TEXT,
    color           TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(org_id, name, type)
);

-- 9. TRANSACTIONS
CREATE TABLE public.transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    period_id           UUID REFERENCES public.festival_periods(id),
    txn_number          TEXT NOT NULL,
    idempotency_key     TEXT UNIQUE,
    type                TEXT NOT NULL,
    amount_paise        BIGINT NOT NULL CHECK (amount_paise > 0),
    date                DATE NOT NULL DEFAULT CURRENT_DATE,
    category_id         UUID REFERENCES public.transaction_categories(id),
    description         TEXT,
    person_name         TEXT,
    person_contact      TEXT,
    payment_method      TEXT NOT NULL DEFAULT 'cash',
    account_id          UUID REFERENCES public.financial_accounts(id),
    reference_number    TEXT,
    to_account_id       UUID REFERENCES public.financial_accounts(id),
    status              TEXT NOT NULL DEFAULT 'active',
    approval_status     TEXT NOT NULL DEFAULT 'approved',
    notes               TEXT,
    tags                TEXT[],
    created_by          UUID NOT NULL REFERENCES public.users(id),
    updated_by          UUID REFERENCES public.users(id),
    voided_by           UUID REFERENCES public.users(id),
    voided_at           TIMESTAMPTZ,
    void_reason         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_org ON public.transactions(org_id);
CREATE INDEX idx_transactions_org_date ON public.transactions(org_id, date DESC);

-- 10. AUDIT LOGS
CREATE TABLE public.audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    action          TEXT NOT NULL,
    old_values      JSONB,
    new_values      JSONB,
    reason          TEXT,
    performed_by    UUID NOT NULL REFERENCES public.users(id),
    performed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION is_org_member(p_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.organization_members
        WHERE org_id = p_org_id
        AND user_id = auth.uid()
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users policy
CREATE POLICY "users_select" ON public.users FOR SELECT USING (true);
CREATE POLICY "users_update" ON public.users FOR UPDATE USING (id = auth.uid());

-- Org policy
CREATE POLICY "org_select" ON public.organizations FOR SELECT USING (is_org_member(id) OR created_by = auth.uid());
CREATE POLICY "org_insert" ON public.organizations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "org_update" ON public.organizations FOR UPDATE USING (is_org_member(id) OR created_by = auth.uid());

-- Org members policy
CREATE POLICY "org_members_select" ON public.organization_members FOR SELECT USING (is_org_member(org_id) OR user_id = auth.uid());
CREATE POLICY "org_members_insert" ON public.organization_members FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Accounts policy
CREATE POLICY "accounts_select" ON public.financial_accounts FOR SELECT USING (is_org_member(org_id));
CREATE POLICY "accounts_insert" ON public.financial_accounts FOR INSERT WITH CHECK (is_org_member(org_id) OR auth.role() = 'authenticated');

-- Transactions policy
CREATE POLICY "txn_select" ON public.transactions FOR SELECT USING (is_org_member(org_id));
CREATE POLICY "txn_insert" ON public.transactions FOR INSERT WITH CHECK (is_org_member(org_id));

-- 12. STORAGE BUCKET POLICIES
-- Public access for avatars and logos
CREATE POLICY "Public Read Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Public Read Logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

-- Authenticated upload policies
CREATE POLICY "Auth Upload Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Auth Upload Logos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos' AND auth.role() = 'authenticated');
CREATE POLICY "Auth Upload Receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');
CREATE POLICY "Auth Read Receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');

