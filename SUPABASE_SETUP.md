# Setting Up Supabase for Mitra App

Follow these simple steps to set up your backend on [Supabase.com](https://supabase.com):

---

## Step 1: Create a Free Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and log in or create a free account.
2. Click **New Project**.
3. Choose your organization and fill in project details:
   - **Name**: `Mitra App`
   - **Database Password**: Set a strong password (save this somewhere secure).
   - **Region**: Select the region closest to your users (e.g., `Mumbai (ap-south-1)` for India).
4. Click **Create new project** and wait 1–2 minutes for initialization.

---

## Step 2: Get Your Project URL & Anon Key

1. Once your project is created, navigate to **Project Settings** (gear icon on bottom left) → **API**.
2. Copy the following values:
   - **Project URL** (e.g., `https://xyzcompany.supabase.co`)
   - **anon / public key** (starts with `ey...`)

3. Open `lib/core/constants/app_constants.dart` in your project and replace:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
   with your actual values!

---

## Step 3: Run the Database Migration Script

1. In your Supabase dashboard, click **SQL Editor** on the left menu (icon with `>_`).
2. Click **New query**.
3. Open the file `supabase_schema.sql` from your project root.
4. Copy the entire contents of `supabase_schema.sql` and paste them into the SQL Editor.
5. Click **Run** (or press `Ctrl + Enter`).
6. You should see a green success message: `Success. No rows returned`.

---

## Step 4: Configure Storage Buckets (for Receipts & Logos)

1. In Supabase dashboard, click **Storage** on the left menu.
2. Click **New Bucket**:
   - Bucket 1: `receipts` (Private)
   - Bucket 2: `logos` (Public)
   - Bucket 3: `avatars` (Public)

---

## Step 5: Test the App!

Run your Flutter app:
```bash
flutter pub get
flutter run
```

You are ready to register users, create organizations, and track transactions!
