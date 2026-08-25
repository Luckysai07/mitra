/// Mitra spacing scale.
///
/// Consistent spacing tokens used throughout the app.
/// Based on a 4dp base unit with harmonious multiples.
abstract final class AppSpacing {
  /// 4dp — tight inline spacing
  static const double xs = 4;

  /// 8dp — compact element spacing
  static const double sm = 8;

  /// 12dp — snug spacing
  static const double md = 12;

  /// 16dp — default content padding
  static const double lg = 16;

  /// 20dp — comfortable spacing
  static const double xl = 20;

  /// 24dp — section spacing
  static const double xxl = 24;

  /// 32dp — large section gaps
  static const double xxxl = 32;

  /// 48dp — hero / visual breathing room
  static const double huge = 48;

  /// 64dp — screen-level padding
  static const double massive = 64;

  // ── Common padding presets ──

  /// Horizontal screen padding (16dp)
  static const double screenHorizontal = lg;

  /// Vertical screen padding (24dp)
  static const double screenVertical = xxl;

  /// Card internal padding (16dp)
  static const double cardPadding = lg;

  /// Bottom nav safe area padding
  static const double bottomNavHeight = 80;

  /// FAB overlap offset
  static const double fabOffset = 56;

  // ── Border Radius ──

  /// Small chips, tags (8dp)
  static const double radiusSm = 8;

  /// Cards, buttons (12dp)
  static const double radiusMd = 12;

  /// Bottom sheets, dialogs (16dp)
  static const double radiusLg = 16;

  /// Full round (pill shape)
  static const double radiusXl = 24;

  /// Circular
  static const double radiusFull = 999;
}
