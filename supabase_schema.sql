-- ============================================================
-- MITRA DIGITAL BOOK — COMPLETE RESILIENT SUPABASE SCHEMA
-- ============================================================
-- Copy and run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ============================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       TEXT NOT NULL DEFAULT 'Member',
    display_name    TEXT,
    email           TEXT,
    phone           TEXT,
    avatar_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);

-- Automatic Auth Trigger for New Users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, email, phone)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            NULLIF(split_part(NEW.email, '@', 1), ''),
            NEW.phone,
            'Member'
        ),
        NEW.email,
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone_number', NEW.raw_user_meta_data->>'phone')
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
        email = COALESCE(EXCLUDED.email, public.users.email),
        phone = COALESCE(EXCLUDED.phone, public.users.phone),
        updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. ORGANIZATIONS TABLE
CREATE TABLE IF NOT EXISTS public.organizations (
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
    created_by      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_organizations_join_code ON public.organizations(join_code);

-- 4. ROLES TABLE
CREATE TABLE IF NOT EXISTS public.roles (
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

-- 5. ORGANIZATION MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.organization_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role            TEXT NOT NULL DEFAULT 'member',
    role_id         UUID REFERENCES public.roles(id) ON DELETE SET NULL,
    status          TEXT NOT NULL DEFAULT 'active',
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(org_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_org_members_user ON public.organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org ON public.organization_members(org_id);

-- 6. FESTIVAL PERIODS
CREATE TABLE IF NOT EXISTS public.festival_periods (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    start_date            DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date              DATE,
    opening_balance_paise BIGINT NOT NULL DEFAULT 0,
    status                TEXT NOT NULL DEFAULT 'active',
    closed_at             TIMESTAMPTZ,
    closed_by             UUID REFERENCES public.users(id),
    closing_report_url    TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. FINANCIAL ACCOUNTS
CREATE TABLE IF NOT EXISTS public.financial_accounts (
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
CREATE TABLE IF NOT EXISTS public.transaction_categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    type            TEXT NOT NULL, -- 'income' or 'expense'
    icon            TEXT,
    color           TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(org_id, name, type)
);

-- 9. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    period_id           UUID REFERENCES public.festival_periods(id) ON DELETE SET NULL,
    txn_number          TEXT NOT NULL,
    idempotency_key     TEXT UNIQUE,
    type                TEXT NOT NULL, -- 'income' or 'expense'
    amount_paise        BIGINT NOT NULL CHECK (amount_paise > 0),
    date                DATE NOT NULL DEFAULT CURRENT_DATE,
    category_id         UUID REFERENCES public.transaction_categories(id) ON DELETE SET NULL,
    description         TEXT,
    person_name         TEXT,
    person_contact      TEXT,
    payment_method      TEXT NOT NULL DEFAULT 'cash',
    account_id          UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL,
    reference_number    TEXT,
    to_account_id       UUID REFERENCES public.financial_accounts(id) ON DELETE SET NULL,
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

CREATE INDEX IF NOT EXISTS idx_transactions_org ON public.transactions(org_id);
CREATE INDEX IF NOT EXISTS idx_transactions_org_date ON public.transactions(org_id, date DESC);

-- 10. AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
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

-- ============================================================
-- AUTO-INITIALIZE ORGANIZATION (TRIGGER FOR INSTANT SETUP)
-- ============================================================
-- When an organization is created, automatically:
-- 1. Add creator as Owner in organization_members
-- 2. Create default roles (Owner, President, Treasurer, Secretary, Member)
-- 3. Create default accounts (Cash Box, Bank / UPI)
-- 4. Seed default income/expense categories
CREATE OR REPLACE FUNCTION public.handle_new_organization()
RETURNS TRIGGER AS $$
DECLARE
    v_owner_role_id UUID;
BEGIN
    -- 1. Insert Default Roles
    INSERT INTO public.roles (org_id, name, display_name, description, is_system, priority)
    VALUES
        (NEW.id, 'owner', 'Owner', 'Full ownership & control', true, 100)
    RETURNING id INTO v_owner_role_id;

    INSERT INTO public.roles (org_id, name, display_name, description, is_system, priority)
    VALUES
        (NEW.id, 'president', 'President', 'Approves budgets & activities', true, 80),
        (NEW.id, 'treasurer', 'Treasurer', 'Manages transactions & ledger', true, 60),
        (NEW.id, 'secretary', 'Secretary', 'Manages members & communications', true, 40),
        (NEW.id, 'member', 'Member', 'General committee member', true, 20),
        (NEW.id, 'viewer', 'Viewer', 'Read-only observer', true, 10)
    ON CONFLICT (org_id, name) DO NOTHING;

    -- 2. Add Organization Creator as Owner
    INSERT INTO public.organization_members (org_id, user_id, role, role_id, status)
    VALUES (NEW.id, NEW.created_by, 'owner', v_owner_role_id, 'active')
    ON CONFLICT (org_id, user_id) DO UPDATE SET
        role = 'owner',
        status = 'active';

    -- 3. Add Default Financial Accounts
    INSERT INTO public.financial_accounts (org_id, name, account_type, is_default, is_active)
    VALUES
        (NEW.id, 'Cash Box', 'cash', true, true),
        (NEW.id, 'Bank Account / UPI', 'bank', false, true);

    -- 4. Seed Default Categories
    INSERT INTO public.transaction_categories (org_id, name, type, icon, color, is_default, sort_order)
    VALUES
        -- Income
        (NEW.id, 'Donations', 'income', 'heart', '#0F9D58', true, 1),
        (NEW.id, 'Sponsorship', 'income', 'handshake', '#1A73E8', true, 2),
        (NEW.id, 'Membership Fees', 'income', 'card_membership', '#5B4CDB', true, 3),
        (NEW.id, 'Fund Collection', 'income', 'savings', '#F4B400', true, 4),
        (NEW.id, 'Other Income', 'income', 'attach_money', '#6B7280', true, 5),
        -- Expense
        (NEW.id, 'Decorations', 'expense', 'palette', '#E91E63', true, 1),
        (NEW.id, 'Prasadam / Food', 'expense', 'restaurant', '#FF5722', true, 2),
        (NEW.id, 'Sound & Music', 'expense', 'music_note', '#9C27B0', true, 3),
        (NEW.id, 'Lighting', 'expense', 'lightbulb', '#FFC107', true, 4),
        (NEW.id, 'Idol / Murti', 'expense', 'temple_hindu', '#FF9800', true, 5),
        (NEW.id, 'Pandal / Stage', 'expense', 'home_work', '#795548', true, 6),
        (NEW.id, 'Puja Materials', 'expense', 'local_fire_department', '#F44336', true, 7),
        (NEW.id, 'Miscellaneous', 'expense', 'more_horiz', '#9E9E9E', true, 8)
    ON CONFLICT (org_id, name, type) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_organization_created ON public.organizations;
CREATE TRIGGER on_organization_created
    AFTER INSERT ON public.organizations
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_organization();

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festival_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper Membership Check
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

-- 1. Users policies
DROP POLICY IF EXISTS "users_select" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;

CREATE POLICY "users_select" ON public.users FOR SELECT USING (true);
CREATE POLICY "users_insert" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "users_update" ON public.users FOR UPDATE USING (id = auth.uid() OR auth.role() = 'authenticated');

-- 2. Organizations policies
DROP POLICY IF EXISTS "org_select" ON public.organizations;
DROP POLICY IF EXISTS "org_insert" ON public.organizations;
DROP POLICY IF EXISTS "org_update" ON public.organizations;
DROP POLICY IF EXISTS "org_delete" ON public.organizations;

CREATE POLICY "org_select" ON public.organizations FOR SELECT USING (true);
CREATE POLICY "org_insert" ON public.organizations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "org_update" ON public.organizations FOR UPDATE USING (created_by = auth.uid() OR is_org_member(id));
CREATE POLICY "org_delete" ON public.organizations FOR DELETE USING (created_by = auth.uid());

-- 3. Roles policies
DROP POLICY IF EXISTS "roles_select" ON public.roles;
DROP POLICY IF EXISTS "roles_insert" ON public.roles;
DROP POLICY IF EXISTS "roles_update" ON public.roles;

CREATE POLICY "roles_select" ON public.roles FOR SELECT USING (true);
CREATE POLICY "roles_insert" ON public.roles FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "roles_update" ON public.roles FOR UPDATE USING (auth.role() = 'authenticated');

-- 4. Organization Members policies
DROP POLICY IF EXISTS "org_members_select" ON public.organization_members;
DROP POLICY IF EXISTS "org_members_insert" ON public.organization_members;
DROP POLICY IF EXISTS "org_members_update" ON public.organization_members;
DROP POLICY IF EXISTS "org_members_delete" ON public.organization_members;

CREATE POLICY "org_members_select" ON public.organization_members FOR SELECT USING (true);
CREATE POLICY "org_members_insert" ON public.organization_members FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "org_members_update" ON public.organization_members FOR UPDATE USING (user_id = auth.uid() OR is_org_member(org_id));
CREATE POLICY "org_members_delete" ON public.organization_members FOR DELETE USING (user_id = auth.uid() OR is_org_member(org_id));

-- 5. Financial Accounts policies
DROP POLICY IF EXISTS "accounts_select" ON public.financial_accounts;
DROP POLICY IF EXISTS "accounts_insert" ON public.financial_accounts;
DROP POLICY IF EXISTS "accounts_update" ON public.financial_accounts;
DROP POLICY IF EXISTS "accounts_delete" ON public.financial_accounts;

CREATE POLICY "accounts_select" ON public.financial_accounts FOR SELECT USING (true);
CREATE POLICY "accounts_insert" ON public.financial_accounts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "accounts_update" ON public.financial_accounts FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "accounts_delete" ON public.financial_accounts FOR DELETE USING (auth.role() = 'authenticated');

-- 6. Transaction Categories policies
DROP POLICY IF EXISTS "categories_select" ON public.transaction_categories;
DROP POLICY IF EXISTS "categories_insert" ON public.transaction_categories;
DROP POLICY IF EXISTS "categories_update" ON public.transaction_categories;
DROP POLICY IF EXISTS "categories_delete" ON public.transaction_categories;

CREATE POLICY "categories_select" ON public.transaction_categories FOR SELECT USING (true);
CREATE POLICY "categories_insert" ON public.transaction_categories FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "categories_update" ON public.transaction_categories FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "categories_delete" ON public.transaction_categories FOR DELETE USING (auth.role() = 'authenticated');

-- 7. Festival Periods policies
DROP POLICY IF EXISTS "periods_select" ON public.festival_periods;
DROP POLICY IF EXISTS "periods_insert" ON public.festival_periods;
DROP POLICY IF EXISTS "periods_update" ON public.festival_periods;

CREATE POLICY "periods_select" ON public.festival_periods FOR SELECT USING (true);
CREATE POLICY "periods_insert" ON public.festival_periods FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "periods_update" ON public.festival_periods FOR UPDATE USING (auth.role() = 'authenticated');

-- 8. Transactions policies
DROP POLICY IF EXISTS "txn_select" ON public.transactions;
DROP POLICY IF EXISTS "txn_insert" ON public.transactions;
DROP POLICY IF EXISTS "txn_update" ON public.transactions;
DROP POLICY IF EXISTS "txn_delete" ON public.transactions;

CREATE POLICY "txn_select" ON public.transactions FOR SELECT USING (true);
CREATE POLICY "txn_insert" ON public.transactions FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "txn_update" ON public.transactions FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "txn_delete" ON public.transactions FOR DELETE USING (auth.role() = 'authenticated');

-- 9. Audit Logs policies
DROP POLICY IF EXISTS "audit_select" ON public.audit_logs;
DROP POLICY IF EXISTS "audit_insert" ON public.audit_logs;

CREATE POLICY "audit_select" ON public.audit_logs FOR SELECT USING (true);
CREATE POLICY "audit_insert" ON public.audit_logs FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE BUCKETS CONFIGURATION
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('logos', 'logos', true),
    ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public Read Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public Read Logos" ON storage.objects;
DROP POLICY IF EXISTS "Public Read Receipts" ON storage.objects;
DROP POLICY IF EXISTS "Auth Upload Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Auth Upload Logos" ON storage.objects;
DROP POLICY IF EXISTS "Auth Upload Receipts" ON storage.objects;

CREATE POLICY "Public Read Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Public Read Logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
CREATE POLICY "Public Read Receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');

CREATE POLICY "Auth Upload Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Auth Upload Logos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos' AND auth.role() = 'authenticated');
CREATE POLICY "Auth Upload Receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');
