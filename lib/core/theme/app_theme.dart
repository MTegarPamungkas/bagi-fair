import 'package:flutter/material.dart';

/// Layout rhythm. Four-point grid, used everywhere instead of loose numbers.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 56;
}

abstract final class AppRadius {
  static const Radius sm = Radius.circular(10);
  static const Radius md = Radius.circular(14);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(26);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius allSm = BorderRadius.all(sm);
  static const BorderRadius allMd = BorderRadius.all(md);
  static const BorderRadius allLg = BorderRadius.all(lg);
  static const BorderRadius allXl = BorderRadius.all(xl);
  static const BorderRadius allPill = BorderRadius.all(pill);
}

/// Bagi Fair design tokens.
///
/// The product metaphor is a shared receipt: warm paper, dark ink, a fair
/// green for "settled" and a tangerine pen for anything that needs attention.
/// The palette is intentionally warmer and flatter than a generic finance
/// dashboard, and cards use a hard offset shadow instead of a soft glow.
@immutable
class FairColors extends ThemeExtension<FairColors> {
  const FairColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.blue,
    required this.blueSoft,
    required this.positive,
    required this.positiveSoft,
    required this.negative,
    required this.negativeSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.shadow,
    required this.glow,
    required this.tang,
    required this.tangSoft,
    required this.stamp,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color blue;
  final Color blueSoft;
  final Color positive;
  final Color positiveSoft;
  final Color negative;
  final Color negativeSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color shadow;
  final Color glow;

  /// Warm secondary used for calls to action and "needs attention" states.
  final Color tang;
  final Color tangSoft;

  /// Ink used by the "Impas" rubber stamp.
  final Color stamp;

  LinearGradient get brandGradient => LinearGradient(
    colors: [accent, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  FairColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? blue,
    Color? blueSoft,
    Color? positive,
    Color? positiveSoft,
    Color? negative,
    Color? negativeSoft,
    Color? warning,
    Color? warningSoft,
    Color? info,
    Color? infoSoft,
    Color? shadow,
    Color? glow,
    Color? tang,
    Color? tangSoft,
    Color? stamp,
  }) {
    return FairColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      positive: positive ?? this.positive,
      positiveSoft: positiveSoft ?? this.positiveSoft,
      negative: negative ?? this.negative,
      negativeSoft: negativeSoft ?? this.negativeSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      shadow: shadow ?? this.shadow,
      glow: glow ?? this.glow,
      tang: tang ?? this.tang,
      tangSoft: tangSoft ?? this.tangSoft,
      stamp: stamp ?? this.stamp,
    );
  }

  @override
  FairColors lerp(covariant FairColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FairColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      line: mix(line, other.line),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccent: mix(onAccent, other.onAccent),
      blue: mix(blue, other.blue),
      blueSoft: mix(blueSoft, other.blueSoft),
      positive: mix(positive, other.positive),
      positiveSoft: mix(positiveSoft, other.positiveSoft),
      negative: mix(negative, other.negative),
      negativeSoft: mix(negativeSoft, other.negativeSoft),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      info: mix(info, other.info),
      infoSoft: mix(infoSoft, other.infoSoft),
      shadow: mix(shadow, other.shadow),
      glow: mix(glow, other.glow),
      tang: mix(tang, other.tang),
      tangSoft: mix(tangSoft, other.tangSoft),
      stamp: mix(stamp, other.stamp),
    );
  }
}

extension FairThemeContext on BuildContext {
  FairColors get fair => Theme.of(this).extension<FairColors>()!;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;
}

class AppTypography {
  AppTypography._();

  /// Geometric sans for the product UI.
  static const String sans = 'Outfit';

  /// Chunky grotesque for headlines: the loud, friendly voice.
  static const String display = 'BricolageGrotesque';

  /// Monospace for every amount, so columns of money line up.
  static const String mono = 'JetBrainsMono';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle money({
    double? fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabular,
    );
  }

  static TextStyle heading({
    double? fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const FairColors _dark = FairColors(
    background: Color(0xFF0B1310),
    surface: Color(0xFF121E19),
    surfaceElevated: Color(0xFF172722),
    surfaceMuted: Color(0xFF1D2F28),
    ink: Color(0xFFF4F0E5),
    inkMuted: Color(0xFF9DAFA5),
    line: Color(0xFF2A3E35),
    accent: Color(0xFF4FDDA4),
    accentSoft: Color(0xFF153A2C),
    onAccent: Color(0xFF042017),
    blue: Color(0xFF8FB8FF),
    blueSoft: Color(0xFF17294A),
    positive: Color(0xFF4FDDA4),
    positiveSoft: Color(0xFF153A2C),
    negative: Color(0xFFFFA093),
    negativeSoft: Color(0xFF3B211D),
    warning: Color(0xFFF5B466),
    warningSoft: Color(0xFF3A2A16),
    info: Color(0xFF8FB8FF),
    infoSoft: Color(0xFF17294A),
    shadow: Color(0x99000000),
    glow: Color(0xFF4FDDA4),
    tang: Color(0xFFFF9C5C),
    tangSoft: Color(0xFF3D2618),
    stamp: Color(0xFF4FDDA4),
  );

  static const FairColors _light = FairColors(
    background: Color(0xFFF4F1E8),
    surface: Color(0xFFFFFDF8),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDE7DA),
    ink: Color(0xFF13241D),
    inkMuted: Color(0xFF5C6B62),
    line: Color(0xFFDED6C6),
    accent: Color(0xFF0C6B54),
    accentSoft: Color(0xFFD8EDE2),
    onAccent: Color(0xFFFFFFFF),
    blue: Color(0xFF1F6FEB),
    blueSoft: Color(0xFFDCE8FC),
    positive: Color(0xFF0C6B54),
    positiveSoft: Color(0xFFD8EDE2),
    negative: Color(0xFFB9473F),
    negativeSoft: Color(0xFFF6DDD9),
    warning: Color(0xFFB25E12),
    warningSoft: Color(0xFFF7E3CF),
    info: Color(0xFF1F6FEB),
    infoSoft: Color(0xFFDCE8FC),
    shadow: Color(0x2413241D),
    glow: Color(0xFF0C6B54),
    tang: Color(0xFFD9551B),
    tangSoft: Color(0xFFFBE3D2),
    stamp: Color(0xFF0C6B54),
  );

  static ThemeData get darkTheme => _theme(_dark, Brightness.dark);

  static ThemeData get lightTheme => _theme(_light, Brightness.light);

  static ThemeData _theme(FairColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    TextStyle display(
      double size,
      FontWeight weight, {
      double height = 1.04,
      double spacing = -1.2,
    }) {
      return AppTypography.heading(
        fontSize: size,
        fontWeight: weight,
        color: colors.ink,
        height: height,
        letterSpacing: spacing,
      );
    }

    TextStyle body(
      double size,
      FontWeight weight, {
      double height = 1.5,
      double spacing = 0,
    }) {
      return TextStyle(
        fontFamily: AppTypography.sans,
        fontSize: size,
        height: height,
        letterSpacing: spacing,
        fontWeight: weight,
        color: colors.ink,
      );
    }

    final textTheme = TextTheme(
      displayLarge: display(46, FontWeight.w800, spacing: -1.8),
      displayMedium: display(36, FontWeight.w800, spacing: -1.4),
      displaySmall: display(29, FontWeight.w700, spacing: -1),
      headlineLarge: display(26, FontWeight.w700, height: 1.1, spacing: -0.8),
      headlineMedium: display(22, FontWeight.w700, height: 1.15, spacing: -0.6),
      headlineSmall: display(19, FontWeight.w600, height: 1.2, spacing: -0.4),
      titleLarge: body(17, FontWeight.w700, height: 1.3, spacing: -0.2),
      titleMedium: body(15, FontWeight.w600, height: 1.35),
      titleSmall: body(13, FontWeight.w600, height: 1.35),
      bodyLarge: body(15.5, FontWeight.w400, height: 1.55, spacing: -0.1),
      bodyMedium: body(13.5, FontWeight.w400, height: 1.5),
      bodySmall: body(
        12,
        FontWeight.w400,
        height: 1.45,
      ).copyWith(color: colors.inkMuted),
      labelLarge: body(13.5, FontWeight.w700, height: 1.2, spacing: 0.1),
      labelMedium: body(
        11.5,
        FontWeight.w600,
        height: 1.2,
      ).copyWith(color: colors.inkMuted, letterSpacing: 0.2),
      labelSmall: AppTypography.money(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: colors.inkMuted,
        letterSpacing: 1.2,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: colors.accentSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFB7F5D8)
          : const Color(0xFF06402B),
      secondary: colors.tang,
      onSecondary: isDark ? const Color(0xFF2B1204) : Colors.white,
      secondaryContainer: colors.tangSoft,
      onSecondaryContainer: isDark
          ? const Color(0xFFFFD9C2)
          : const Color(0xFF4A1A05),
      tertiary: colors.blue,
      onTertiary: isDark ? const Color(0xFF061B3D) : Colors.white,
      tertiaryContainer: colors.blueSoft,
      onTertiaryContainer: isDark
          ? const Color(0xFFCFE0FF)
          : const Color(0xFF0B2A63),
      error: colors.negative,
      onError: isDark ? const Color(0xFF3B0905) : Colors.white,
      errorContainer: colors.negativeSoft,
      onErrorContainer: isDark
          ? const Color(0xFFFFD6D0)
          : const Color(0xFF5B120E),
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.surfaceMuted,
      onSurfaceVariant: colors.inkMuted,
      outline: colors.line,
      outlineVariant: colors.line.withValues(alpha: 0.65),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: colors.ink,
      onInverseSurface: colors.background,
      inversePrimary: colors.accentSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: AppTypography.sans,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerColor: colors.line,
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: 0.24),
        selectionHandleColor: colors.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.negative),
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.negative),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: colors.negative, width: 1.6),
        ),
        prefixIconColor: colors.inkMuted,
        suffixIconColor: colors.inkMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.inkMuted,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          side: BorderSide(color: colors.line),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.inkMuted,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.tang,
        foregroundColor: isDark ? colors.onAccent : Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          color: isDark ? colors.onAccent : Colors.white,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.accentSoft,
        disabledColor: colors.surfaceMuted,
        side: BorderSide(color: colors.line),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium!.copyWith(
            fontSize: 10.5,
            letterSpacing: 0.1,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colors.ink : colors.inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? colors.accent : colors.inkMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSoft,
        selectedIconTheme: IconThemeData(color: colors.accent),
        unselectedIconTheme: IconThemeData(color: colors.inkMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.inkMuted,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        modalBarrierColor: colors.ink.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.xl),
        ),
        showDragHandle: true,
        dragHandleColor: colors.line,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.background,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        insetPadding: const EdgeInsets.all(16),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: AppRadius.allSm,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.background),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.onAccent;
          return colors.inkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.line,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return colors.accentSoft;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return colors.accent;
            return colors.inkMuted;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: colors.line)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colors.surfaceMuted,
        headerForegroundColor: colors.ink,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.line),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.inkMuted,
        textColor: colors.ink,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
