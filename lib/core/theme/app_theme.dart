import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.starlightWhite.withValues(alpha: 0.28),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.spaceBlack,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.spaceBlack,
        primary: AppColors.starlightWhite,
        secondary: AppColors.calm,
        onPrimary: AppColors.spaceBlack,
        onSurface: AppColors.starlightWhite,
      ),
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: AppColors.starlightWhite,
        displayColor: AppColors.starlightWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.starlightWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.deepCharcoal,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.deepCharcoal,
        contentTextStyle: TextStyle(color: AppColors.starlightWhite),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.deepCharcoal,
        labelStyle: const TextStyle(color: AppColors.starlightWhite),
        counterStyle: TextStyle(
          color: AppColors.starlightWhite.withValues(alpha: 0.7),
        ),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.starlightWhite),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.anger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.anger),
        ),
      ),
    );
  }
}
