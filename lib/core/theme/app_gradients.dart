import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E6B3E), AppColors.seed, Color(0xFF6FA85A)],
  );

  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.seed, Color(0xFF5A9950)],
  );
}
