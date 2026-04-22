import 'package:controle_instrumentos/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const pageTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.surfaceDark,
  );

  static const sectionSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const badge = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}
