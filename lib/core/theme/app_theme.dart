import 'package:flutter/material.dart';

// --- Theme Extensions ---

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryLight;
  final Color primarySurface;
  final Color accent;
  final Color accentSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;
  final Color success;
  final Color successSurface;
  final Color info;
  final Color infoSurface;
  final Color surface;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primarySurface,
    required this.accent,
    required this.accentSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.success,
    required this.successSurface,
    required this.info,
    required this.infoSurface,
    required this.surface,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primarySurface,
    Color? accent,
    Color? accentSurface,
    Color? warning,
    Color? warningSurface,
    Color? danger,
    Color? dangerSurface,
    Color? success,
    Color? successSurface,
    Color? info,
    Color? infoSurface,
    Color? surface,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySurface: primarySurface ?? this.primarySurface,
      accent: accent ?? this.accent,
      accentSurface: accentSurface ?? this.accentSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
      surface: surface ?? this.surface,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}

class AppTextExtension extends ThemeExtension<AppTextExtension> {
  final TextStyle headingLarge;
  final TextStyle headingMedium;
  final TextStyle headingSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelBold;
  final TextStyle valueDisplay;

  const AppTextExtension({
    required this.headingLarge,
    required this.headingMedium,
    required this.headingSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelBold,
    required this.valueDisplay,
  });

  @override
  AppTextExtension copyWith({
    TextStyle? headingLarge,
    TextStyle? headingMedium,
    TextStyle? headingSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelBold,
    TextStyle? valueDisplay,
  }) {
    return AppTextExtension(
      headingLarge: headingLarge ?? this.headingLarge,
      headingMedium: headingMedium ?? this.headingMedium,
      headingSmall: headingSmall ?? this.headingSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelBold: labelBold ?? this.labelBold,
      valueDisplay: valueDisplay ?? this.valueDisplay,
    );
  }

  @override
  AppTextExtension lerp(ThemeExtension<AppTextExtension>? other, double t) {
    if (other is! AppTextExtension) {
      return this;
    }
    return AppTextExtension(
      headingLarge: TextStyle.lerp(headingLarge, other.headingLarge, t)!,
      headingMedium: TextStyle.lerp(headingMedium, other.headingMedium, t)!,
      headingSmall: TextStyle.lerp(headingSmall, other.headingSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelBold: TextStyle.lerp(labelBold, other.labelBold, t)!,
      valueDisplay: TextStyle.lerp(valueDisplay, other.valueDisplay, t)!,
    );
  }
}

class AppTheme {
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

  // ── Helpers ──────────────────────────────────────────────────────────
  static AppColorsExtension colors(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>()!;
  static AppTextExtension text(BuildContext context) =>
      Theme.of(context).extension<AppTextExtension>()!;
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: colors(context).cardBackground,
    borderRadius: radiusMd,
    boxShadow: cardShadow,
  );

  // ── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colors = AppColorsExtension(
      primary: Color(0xFF1B5E20),
      primaryLight: Color(0xFF4CAF50),
      primarySurface: Color(0x1A1B5E20),
      accent: Color(0xFF00897B),
      accentSurface: Color(0x1A00897B),
      warning: Color(0xFFE65100),
      warningSurface: Color(0x1AE65100),
      danger: Color(0xFFC62828),
      dangerSurface: Color(0x1AC62828),
      success: Color(0xFF2E7D32),
      successSurface: Color(0x1A2E7D32),
      info: Color(0xFF7B1FA2),
      infoSurface: Color(0x1A7B1FA2),
      surface: Color(0xFFF5F7FA),
      cardBackground: Colors.white,
      textPrimary: Color(0xFF1A1A2E),
      textSecondary: Color(0xFF6B7280),
      textTertiary: Color(0xFF9CA3AF),
    );

    final text = AppTextExtension(
      headingLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.5,
      ),
      headingMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headingSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textTertiary,
      ),
      labelBold: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.3,
      ),
      valueDisplay: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.3,
      ),
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
      ),
      extensions: [colors, text],
      useMaterial3: true,
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colors = AppColorsExtension(
      primary: Color(0xFF4CAF50),
      primaryLight: Color(0xFF81C784),
      primarySurface: Color(0x264CAF50),
      accent: Color(0xFF26A69A),
      accentSurface: Color(0x2626A69A),
      warning: Color(0xFFFF9800),
      warningSurface: Color(0x26FF9800),
      danger: Color(0xFFEF5350),
      dangerSurface: Color(0x26EF5350),
      success: Color(0xFF66BB6A),
      successSurface: Color(0x2666BB6A),
      info: Color(0xFFCE93D8),
      infoSurface: Color(0x26CE93D8),
      surface: Color(0xFF121212),
      cardBackground: Color(0xFF1E1E1E),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFAAAAAA),
      textTertiary: Color(0xFF777777),
    );

    final text = AppTextExtension(
      headingLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.5,
      ),
      headingMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headingSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textTertiary,
      ),
      labelBold: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.3,
      ),
      valueDisplay: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: -0.3,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.dark,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      extensions: [colors, text],
      useMaterial3: true,
    );
  }
}
