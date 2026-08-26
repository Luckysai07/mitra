/// App-wide constants for Mitra.
abstract final class AppConstants {
  // ── App Info & Developer Copyright ──
  static const String appName = 'Mitra';
  static const String appTagline =
      'Your organization\'s digital book — transparent, accountable, simple.';
  static const String appPackage = 'com.mitra.app';
  static const String developerName = 'Kadega Sai Kumar';
  static const String developerRole = 'Full Stack Developer & AI Systems Engineer';
  static const String developerPortfolioUrl = 'https://saikumar-devfolio.vercel.app/';
  static const String developerGithubUrl = 'https://github.com/Luckysai07';
  static const String developerLinkedinUrl = 'https://www.linkedin.com/in/k-sai-kumar-5a5a85338';
  static const String developerEmail = 'saikumarkadega@gmail.com';
  static const String copyrightNotice = '© 2026 Kadega Sai Kumar. All rights reserved.';
  static const String appVersion = '1.0.0';
  static const String githubRepo = 'Luckysai07/mitra';
  static const String githubReleasesApiUrl = 'https://api.github.com/repos/Luckysai07/mitra/releases/latest';
  static const String apkDownloadUrl = 'https://github.com/Luckysai07/mitra/releases/download/latest/mitra-app.apk';
  static const String vercelDownloadUrl = 'https://github.com/Luckysai07/mitra/releases/download/latest/mitra-app.apk';

  // ── Supabase ──
  static const String supabaseUrl = 'https://lrfxmicmalgglnbadcfh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxyZnhtaWNtYWxnZ2xuYmFkY2ZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1ODAxOTMsImV4cCI6MjEwMzE1NjE5M30.3ARLIVgLvgRJSTaOE088F0zu0OcfB0IdoZAI1HLWEDs';

  // ── Currency ──
  static const String defaultCurrencyCode = 'INR';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultLocale = 'en_IN';

  // ── Pagination ──
  static const int defaultPageSize = 20;
  static const int transactionPageSize = 20;
  static const int memberPageSize = 50;

  // ── Validation ──
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;
  static const int joinCodeLength = 8;

  // ── File Limits ──
  static const int maxReceiptFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxLogoFileSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const List<String> allowedReceiptExtensions = [
    'jpg', 'jpeg', 'png', 'pdf',
  ];
  static const List<String> allowedLogoExtensions = [
    'jpg', 'jpeg', 'png',
  ];

  // ── Transaction Number Format ──
  static const String txnPrefix = 'TXN';
  static const String receiptPrefix = 'RCT';
  static const int counterPadding = 5; // TXN-00001

  // ── Approval ──
  static const int defaultApprovalThresholdPaise = 200000; // ₹2,000

  // ── Storage Buckets ──
  static const String receiptsBucket = 'receipts';
  static const String logosBucket = 'logos';
  static const String avatarsBucket = 'avatars';

  // ── Animations ──
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 250);

  // ── Debounce ──
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration syncDebounce = Duration(seconds: 2);
}

/// Default transaction categories seeded for each new organization.
///
/// Festival-inspired defaults (Ganesh Utsav, Durga Puja, etc.)
/// Users can customize, add, or remove categories.
abstract final class DefaultCategories {
  static const List<Map<String, dynamic>> income = [
    {'name': 'Donations', 'icon': 'heart', 'color': '#0F9D58'},
    {'name': 'Sponsorship', 'icon': 'handshake', 'color': '#1A73E8'},
    {'name': 'Membership Fees', 'icon': 'card_membership', 'color': '#5B4CDB'},
    {'name': 'Fund Collection', 'icon': 'savings', 'color': '#F4B400'},
    {'name': 'Interest', 'icon': 'trending_up', 'color': '#34A853'},
    {'name': 'Other Income', 'icon': 'attach_money', 'color': '#6B7280'},
  ];

  static const List<Map<String, dynamic>> expense = [
    {'name': 'Decorations', 'icon': 'palette', 'color': '#E91E63'},
    {'name': 'Prasadam / Food', 'icon': 'restaurant', 'color': '#FF5722'},
    {'name': 'Sound & Music', 'icon': 'music_note', 'color': '#9C27B0'},
    {'name': 'Lighting', 'icon': 'lightbulb', 'color': '#FFC107'},
    {'name': 'Idol / Murti', 'icon': 'temple_hindu', 'color': '#FF9800'},
    {'name': 'Pandal / Stage', 'icon': 'home_work', 'color': '#795548'},
    {'name': 'Transport', 'icon': 'local_shipping', 'color': '#607D8B'},
    {'name': 'Puja Materials', 'icon': 'local_fire_department', 'color': '#F44336'},
    {'name': 'Printing', 'icon': 'print', 'color': '#3F51B5'},
    {'name': 'Electricity', 'icon': 'bolt', 'color': '#FFEB3B'},
    {'name': 'Rent', 'icon': 'location_city', 'color': '#00BCD4'},
    {'name': 'Miscellaneous', 'icon': 'more_horiz', 'color': '#9E9E9E'},
  ];
}

/// System role definitions.
abstract final class SystemRoles {
  static const String owner = 'owner';
  static const String president = 'president';
  static const String treasurer = 'treasurer';
  static const String secretary = 'secretary';
  static const String member = 'member';
  static const String viewer = 'viewer';

  static const List<Map<String, dynamic>> defaults = [
    {
      'name': owner,
      'display_name': 'Owner',
      'description': 'Full control over the organization',
      'priority': 100,
      'is_system': true,
    },
    {
      'name': president,
      'display_name': 'President',
      'description': 'Manages organization and approves transactions',
      'priority': 80,
      'is_system': true,
    },
    {
      'name': treasurer,
      'display_name': 'Treasurer',
      'description': 'Manages finances, creates and edits transactions',
      'priority': 60,
      'is_system': true,
    },
    {
      'name': secretary,
      'display_name': 'Secretary',
      'description': 'Manages members, events, and communications',
      'priority': 40,
      'is_system': true,
    },
    {
      'name': member,
      'display_name': 'Member',
      'description': 'Can view transactions and reports',
      'priority': 20,
      'is_system': true,
    },
    {
      'name': viewer,
      'display_name': 'Viewer',
      'description': 'Read-only access with audit visibility',
      'priority': 10,
      'is_system': true,
    },
  ];
}
