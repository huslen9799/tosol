import 'package:flutter/material.dart';

import 'brand.dart';

final appThemeMode = ValueNotifier(ThemeMode.system);

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xFF202838) : Colors.white;
  final background = dark ? const Color(0xFF141B27) : const Color(0xFFF7FAFD);
  final text = dark ? const Color(0xFFF4F7FC) : Colors.black;
  final border = dark ? const Color(0xFF3B4860) : const Color(0xFFDCE6F4);
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.turquoise,
    brightness: brightness,
    primary: AppColors.turquoise,
    secondary: AppColors.blue,
    tertiary: AppColors.lavender,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: text,
    outline: border,
    primaryContainer: dark ? const Color(0xFF254B49) : AppColors.light,
    onPrimaryContainer: text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      bodyColor: text,
      displayColor: text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 1,
      shadowColor: AppColors.blue.withValues(alpha: .14),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: TextStyle(color: text.withValues(alpha: .65)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.turquoise,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: text),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: surface,
        foregroundColor: text,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.turquoise
              : surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.black : text,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: AppColors.turquoise,
      labelStyle: TextStyle(
        color: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.black : text,
        ),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: AppColors.turquoise,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? Colors.black : text,
        ),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.turquoise,
      foregroundColor: Colors.black,
    ),
  );
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Гэгээлэг горим' : 'Бараан горим',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () =>
          appThemeMode.value = dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
