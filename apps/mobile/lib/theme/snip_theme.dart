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
      ).copyWith(
        onSurface: SnipColors.textPrimary,
        onSurfaceVariant: SnipColors.secondaryText,
        outline: SnipColors.border,
      ),
      scaffoldBackgroundColor: SnipColors.background,
      textTheme: SnipTypography.textTheme,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: SnipColors.surface,
        foregroundColor: SnipColors.dark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: SnipTypography.textTheme.titleLarge?.copyWith(
          color: SnipColors.dark,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SnipColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
          side: const BorderSide(color: SnipColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SnipColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.lg,
          vertical: SnipSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: const BorderSide(color: SnipColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
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
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          ),
          textStyle: SnipTypography.textTheme.labelLarge?.copyWith(
            color: SnipColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SnipColors.dark,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: SnipColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          ),
          textStyle: SnipTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SnipColors.primary,
          textStyle: SnipTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: SnipColors.white,
        indicatorColor: SnipColors.primaryMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: SnipColors.primary);
          }
          return const IconThemeData(color: SnipColors.secondaryText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return SnipTypography.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? SnipColors.primary : SnipColors.secondaryText,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: SnipColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SnipColors.primary,
        primary: SnipColors.primary,
        secondary: SnipColors.primaryLight,
        surface: SnipColors.darkSurface,
        error: SnipColors.error,
        brightness: Brightness.dark,
      ).copyWith(
        onSurface: SnipColors.darkTextPrimary,
        onSurfaceVariant: SnipColors.darkTextSecondary,
        outline: SnipColors.darkBorder,
        surfaceContainerHighest: SnipColors.darkSurfaceElevated,
      ),
      scaffoldBackgroundColor: SnipColors.darkBackground,
      textTheme: SnipTypography.darkTextTheme,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: SnipColors.darkSurface,
        foregroundColor: SnipColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: SnipTypography.darkTextTheme.titleLarge?.copyWith(
          color: SnipColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SnipColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
          side: const BorderSide(color: SnipColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SnipColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnipSpacing.lg,
          vertical: SnipSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: const BorderSide(color: SnipColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: const BorderSide(color: SnipColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          borderSide: const BorderSide(color: SnipColors.error),
        ),
        hintStyle: SnipTypography.darkTextTheme.bodyMedium?.copyWith(
          color: SnipColors.darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SnipColors.primary,
          foregroundColor: SnipColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          ),
          textStyle: SnipTypography.darkTextTheme.labelLarge?.copyWith(
            color: SnipColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SnipColors.darkTextPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: SnipColors.darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnipSpacing.radiusPill),
          ),
          textStyle: SnipTypography.darkTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SnipColors.primaryLight,
          textStyle: SnipTypography.darkTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: SnipColors.darkSurface,
        indicatorColor: SnipColors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: SnipColors.primary);
          }
          return const IconThemeData(color: SnipColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return SnipTypography.darkTextTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? SnipColors.primary : SnipColors.darkTextSecondary,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: SnipColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: SnipColors.darkTextPrimary),
      listTileTheme: const ListTileThemeData(
        iconColor: SnipColors.darkTextSecondary,
        textColor: SnipColors.darkTextPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SnipColors.darkSurfaceElevated,
        selectedColor: SnipColors.primary.withValues(alpha: 0.22),
        disabledColor: SnipColors.darkSurface,
        labelStyle: const TextStyle(
          color: SnipColors.darkTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: SnipColors.darkTextPrimary,
        ),
        side: const BorderSide(color: SnipColors.darkBorder),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: SnipColors.darkSurfaceElevated,
        contentTextStyle: TextStyle(color: SnipColors.darkTextPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SnipColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnipSpacing.radiusLg),
          side: const BorderSide(color: SnipColors.darkBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SnipColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
