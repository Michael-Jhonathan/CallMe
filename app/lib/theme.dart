import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CallMeThemeExtension extends ThemeExtension<CallMeThemeExtension> {
  final String? backgroundImagePath;

  const CallMeThemeExtension({this.backgroundImagePath});

  @override
  ThemeExtension<CallMeThemeExtension> copyWith({String? backgroundImagePath}) {
    return CallMeThemeExtension(
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  @override
  ThemeExtension<CallMeThemeExtension> lerp(
    covariant ThemeExtension<CallMeThemeExtension>? other,
    double t,
  ) {
    if (other is! CallMeThemeExtension) return this;
    return CallMeThemeExtension(
      backgroundImagePath: t < 0.5
          ? backgroundImagePath
          : other.backgroundImagePath,
    );
  }
}

class CallMeTheme {
  // Cores extraídas do HTML (Tailwind)
  static const Color background = Color(0xFF111317);
  static const Color onBackground = Color(0xFFe2e2e8);
  static const Color surface = Color(0xFF111317);
  static const Color onSurface = Color(0xFFe2e2e8);

  static const Color surfaceContainerLowest = Color(0xFF0c0e12);
  static const Color surfaceContainerLow = Color(0xFF1a1c20);
  static const Color surfaceContainer = Color(0xFF1e2024);
  static const Color surfaceContainerHigh = Color(0xFF282a2e);
  static const Color surfaceContainerHighest = Color(0xFF333539);

  static const Color surfaceBright = Color(0xFF37393e);
  static const Color surfaceDim = Color(0xFF111317);
  static const Color surfaceVariant = Color(0xFF333539);
  static const Color onSurfaceVariant = Color(0xFFc6c5d7);

  static const Color outline = Color(0xFF8f8fa0);
  static const Color outlineVariant = Color(0xFF454655);
  static const Color inverseSurface = Color(0xFFe2e2e8);
  static const Color inverseOnSurface = Color(0xFF2f3035);

  // Cores dinâmicas (Removido const para permitir mutação no Settings)
  static Color primary = const Color(0xFFbec2ff);
  static Color onPrimary = const Color(0xFF000da4);
  static Color primaryContainer = const Color(
    0xFF5865f2,
  ); // Discord classic blue/purple
  static Color onPrimaryContainer = const Color(0xFFfffdff);
  static Color inversePrimary = const Color(0xFF3f4cda);

  static String currentFontFamily = 'Inter';

  static const Color secondary = Color(0xFF66de8b);
  static const Color onSecondary = Color(0xFF003919);
  static const Color secondaryContainer = Color(0xFF24a559);
  static const Color onSecondaryContainer = Color(0xFF003115);

  static const Color tertiary = Color(0xFFffb3ae);
  static const Color onTertiary = Color(0xFF68000c);
  static const Color tertiaryContainer = Color(0xFFdd2f36);
  static const Color onTertiaryContainer = Color(0xFFfffcff);

  static const Color error = Color(0xFFffb4ab);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000a);
  static const Color onErrorContainer = Color(0xFFffdad6);

  static void updatePrimaryColor(Color newPrimary) {
    primary = newPrimary;
    // Cálculos simplificados de tons baseados na cor escolhida para manter a estética
    // Normalmente seriam algoritmos de HSL, mas aqui fazemos de forma direta
    HSLColor hsl = HSLColor.fromColor(newPrimary);

    // onPrimary (Tom muito escuro da mesma cor)
    onPrimary = hsl.withLightness(0.1).toColor();

    // primaryContainer (Tom médio para fundo de botões)
    primaryContainer = hsl.withLightness(0.4).toColor();

    // onPrimaryContainer (Tom muito claro para texto no botão)
    onPrimaryContainer = Color(
      hsl
          .withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0))
          .toColor()
          .toARGB32(),
    );

    // inversePrimary (Para usar em alguns detalhes inversos)
    inversePrimary = hsl.withLightness(0.7).toColor();
  }

  static void updateFontFamily(String font) {
    currentFontFamily = font;
  }

  static ColorScheme get darkColorScheme => ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: primary,
  );

  // O Flutter 3 possui construtores de ColorScheme que não mapeiam tudo no default const.
  // Caso existam as novas cores (surfaceContainer), o copyWith é necessário
  static ColorScheme get customDarkColorScheme => darkColorScheme.copyWith(
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceBright: surfaceBright,
    surfaceDim: surfaceDim,
  );

  static TextTheme get textTheme {
    return GoogleFonts.getTextTheme(
      currentFontFamily,
      const TextTheme(
        // display-lg
        displayLarge: TextStyle(
          fontSize: 32,
          height: 40 / 32,
          letterSpacing: -0.64,
          fontWeight: FontWeight.w700,
        ),
        // headline-md
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 32 / 24,
          fontWeight: FontWeight.w600,
        ),
        // title-sm
        titleSmall: TextStyle(
          fontSize: 18,
          height: 24 / 18,
          fontWeight: FontWeight.w600,
        ),
        // body-md
        bodyMedium: TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w400,
        ),
        // body-sm
        bodySmall: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
        ),
        // label-caps
        labelSmall: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).apply(bodyColor: onSurface, displayColor: onSurface);
  }

  static ThemeData get darkTheme {
    final colorScheme = customDarkColorScheme;

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          Colors.transparent, // Permite que a imagem de fundo apareça!
      textTheme: textTheme,
      extensions: const [CallMeThemeExtension(backgroundImagePath: null)],
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0, // M3 default remove
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: onSurface),
        iconTheme: IconThemeData(color: primary),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        elevation: 0,
      ),
    );
  }

  // --- Deprecated Getters para compatibilidade com o código anterior ---
  @Deprecated('Use surfaceContainerLowest')
  static const Color surfaceLowest = surfaceContainerLowest;

  @Deprecated('Use surfaceContainerLow')
  static const Color surfaceLow = surfaceContainerLow;

  @Deprecated('Use onSurfaceVariant')
  static const Color secondaryFixed = Color(0xFF83fba4);
}
