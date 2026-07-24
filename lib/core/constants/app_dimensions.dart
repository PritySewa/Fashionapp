/// Spacing, border radius, icon sizes, and responsive breakpoints.
abstract final class AppDimensions {
  // ── Spacing scale (4pt grid) ───────────────────────────────────────────────
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ── Border radii ───────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  // ── Icon sizes ─────────────────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const double sidebarWidth = 256;
  static const double sidebarCollapsedWidth = 72;

  // ── App Bar ────────────────────────────────────────────────────────────────
  static const double appBarHeight = 64;

  // ── Breakpoints (px) ──────────────────────────────────────────────────────
  /// Mobile: < 768
  static const double mobileBreakpoint = 768;

  /// Tablet: 768 – 1200
  static const double tabletBreakpoint = 1200;

  /// Desktop: >= 1200
  static const double desktopBreakpoint = 1440;

  // ── Card / Container ──────────────────────────────────────────────────────
  static const double cardElevation = 0;
  static const double cardPadding = space6;
  static const double pagePadding = space8;
}
