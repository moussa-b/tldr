import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens from DESIGN.md (« Céladon »). Change DESIGN.md first, then here.
class Tokens {
  const Tokens._();

  // Spacing (DESIGN.md `spacing`)
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const gutter = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const section = 48.0;
  static const xxl = 72.0;

  // Radii (DESIGN.md `rounded`)
  static const rXs = 4.0;
  static const rSm = 6.0;
  static const rMd = 8.0;
  static const rLg = 12.0;

  static const maxContentWidth = 640.0;
}

/// Semantic colours that are not Material roles (DESIGN.md `colors`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.negative,
    required this.accent,
  });

  final Color positive;
  final Color negative;

  /// Reddit orange: provenance marks only, never text or actions.
  final Color accent;

  static const light = AppColors(
    positive: Color(0xFF2E6B3F),
    negative: Color(0xFF8A4B14),
    accent: Color(0xFFFF4500),
  );

  static const dark = AppColors(
    positive: Color(0xFF8FD19E),
    negative: Color(0xFFE8B27A),
    accent: Color(0xFFFF6A33),
  );

  @override
  AppColors copyWith({Color? positive, Color? negative, Color? accent}) => AppColors(
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        accent: accent ?? this.accent,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  AppText get text => AppText.of(this);
}

/// Font access. Tests set [useGoogleFonts] to false to avoid network fetches.
class AppFonts {
  const AppFonts._();

  static bool useGoogleFonts = true;

  static TextStyle ui(TextStyle style) =>
      useGoogleFonts ? GoogleFonts.ibmPlexSans(textStyle: style) : style;

  static TextStyle reading(TextStyle style) =>
      useGoogleFonts ? GoogleFonts.literata(textStyle: style) : style;
}

/// Text styles per element (DESIGN.md « Typography »).
class AppText {
  AppText._(this._color, this._muted);

  factory AppText.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppText._(scheme.onSurface, scheme.onSurfaceVariant);
  }

  final Color _color;
  final Color _muted;

  static TextStyle _ui(double size, double height, FontWeight weight, Color color,
          {double spacing = 0}) =>
      AppFonts.ui(TextStyle(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing));

  static TextStyle _read(double size, double height, Color color) => AppFonts.reading(
      TextStyle(fontSize: size, height: height / size, fontWeight: FontWeight.w400, color: color));

  TextStyle get wordmark => _ui(20, 24, FontWeight.w600, _color, spacing: -0.2);
  TextStyle get titleThread => _ui(24, 30, FontWeight.w600, _color);
  TextStyle get titleScreen => _ui(20, 28, FontWeight.w600, _color);
  TextStyle get sectionLabel => _ui(14, 20, FontWeight.w600, _color);
  TextStyle get readingLead => _read(20, 30, _color);
  TextStyle get readingBody => _read(17, 27, _color);
  TextStyle get readingOpinion => _read(16, 25, _color);
  TextStyle get verdict => _ui(15, 22, FontWeight.w500, _color);
  TextStyle get body => _ui(16, 24, FontWeight.w400, _color);
  TextStyle get bodyMuted => _ui(16, 24, FontWeight.w400, _muted);
  TextStyle get listTitle => _ui(16, 22, FontWeight.w500, _color);
  TextStyle get meta => _ui(13, 18, FontWeight.w400, _muted);
  TextStyle get label => _ui(14, 20, FontWeight.w500, _color);
  TextStyle get caption => _ui(12, 16, FontWeight.w400, _muted)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

class AppTheme {
  const AppTheme._();

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F5D57),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF3E5B7A),
    onSecondary: Color(0xFFFFFFFF),
    tertiary: Color(0xFF3E5B7A),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFEEF1EC),
    onSurface: Color(0xFF1D2422),
    onSurfaceVariant: Color(0xFF4E5A56),
    surfaceContainerLowest: Color(0xFFF7F9F6),
    surfaceContainerLow: Color(0xFFE8ECE7),
    surfaceContainer: Color(0xFFE5E9E4),
    surfaceContainerHigh: Color(0xFFE2E7E1),
    surfaceContainerHighest: Color(0xFFD8DED7),
    outline: Color(0xFF75817C),
    outlineVariant: Color(0xFFC5CDC7),
    inverseSurface: Color(0xFF2B3230),
    onInverseSurface: Color(0xFFEEF1EC),
    inversePrimary: Color(0xFF9CCFC6),
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9CCFC6),
    onPrimary: Color(0xFF00352F),
    secondary: Color(0xFFA9C4E6),
    onSecondary: Color(0xFF0F2A44),
    tertiary: Color(0xFFA9C4E6),
    onTertiary: Color(0xFF0F2A44),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF121816),
    onSurface: Color(0xFFDDE4E0),
    onSurfaceVariant: Color(0xFFA3B0AB),
    surfaceContainerLowest: Color(0xFF0D1211),
    surfaceContainerLow: Color(0xFF171E1C),
    surfaceContainer: Color(0xFF1A2220),
    surfaceContainerHigh: Color(0xFF1F2724),
    surfaceContainerHighest: Color(0xFF29322F),
    outline: Color(0xFF87938E),
    outlineVariant: Color(0xFF3A4541),
    inverseSurface: Color(0xFFDDE4E0),
    onInverseSurface: Color(0xFF1D2422),
    inversePrimary: Color(0xFF2F5D57),
  );

  static ThemeData light() => _build(_light, AppColors.light);
  static ThemeData dark() => _build(_dark, AppColors.dark);

  static ThemeData _build(ColorScheme scheme, AppColors colors) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
    );
    final textTheme = AppFonts.useGoogleFonts
        ? GoogleFonts.ibmPlexSansTextTheme(base.textTheme)
        : base.textTheme;
    final shape8 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rMd));
    final shape6 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rSm));
    return base.copyWith(
      textTheme: textTheme.apply(
          bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleSpacing: Tokens.gutter,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shape8,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.md),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shape8,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape8, minimumSize: const Size(48, 48)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(shape6),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.rSm),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.rSm),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.rSm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape8,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rLg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(elevation: 0),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
