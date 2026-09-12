import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'snip_colors.dart';
import 'snip_spacing.dart';
import 'snip_typography.dart';

abstract final class SnipTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SnipColors.primary,
        primary: SnipColors.primary,
        secondary: SnipColors.primaryLight,
        surface: SnipColors.surface,
        error: SnipColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: SnipColors.background,
      textTheme: SnipTypography.textTheme,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: SnipColors.white,
        foregroundColor: SnipColors.dark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: SnipTypography.textTheme.headlineSmall,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SnipColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SnipColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.md,
          vertical: SnipSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          borderSide: const BorderSide(color: SnipColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          borderSide: const BorderSide(color: SnipColors.error),
        ),
        hintStyle: SnipTypography.textTheme.bodyMedium?.copyWith(
          color: SnipColors.secondaryText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SnipColors.primary,
          foregroundColor: SnipColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          ),
          textStyle: SnipTypography.textTheme.labelLarge?.copyWith(
            color: SnipColors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SnipColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: SnipColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: SnipColors.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SnipColors.lightGray,
        selectedColor: SnipColors.primary.withValues(alpha: 0.12),
        labelStyle: SnipTypography.textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.sm,
          vertical: SnipSpacing.xs,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SnipColors.white,
        selectedItemColor: SnipColors.primary,
        unselectedItemColor: SnipColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: SnipColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SnipColors.dark,
        contentTextStyle: SnipTypography.textTheme.bodyMedium?.copyWith(
          color: SnipColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusSm),
        ),
      ),
    );
  }
}
