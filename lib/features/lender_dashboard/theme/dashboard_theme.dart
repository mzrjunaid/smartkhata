import 'package:flutter/material.dart';

/// Centralized design tokens for the lender dashboard feature.
///
/// Keeps the entire feature visually consistent and easy to re-skin.
abstract final class DashboardTheme {
  // ── Colors ───────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFE8F5E9);

  static const Color accent = Color(0xFF00897B);
  static const Color accentSurface = Color(0xFFE0F2F1);

  static const Color warning = Color(0xFFE65100);
  static const Color warningSurface = Color(0xFFFFF3E0);

  static const Color danger = Color(0xFFC62828);
  static const Color dangerSurface = Color(0xFFFFEBEE);

  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);

  static const Color surface = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Spacing ──────────────────────────────────────────────────────────

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;

  // ── Border Radius ────────────────────────────────────────────────────

  static final BorderRadius radiusSm = BorderRadius.circular(8);
  static final BorderRadius radiusMd = BorderRadius.circular(12);
  static final BorderRadius radiusLg = BorderRadius.circular(16);
  static final BorderRadius radiusXl = BorderRadius.circular(20);

  // ── Shadows ──────────────────────────────────────────────────────────

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Text Styles ──────────────────────────────────────────────────────

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle valueDisplay = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  // ── Card Decoration ──────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground,
        borderRadius: radiusMd,
        boxShadow: cardShadow,
      );
}
