import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors from Figma
  static const Color primary = Color(0xFF339F91);
  static const Color primaryLight = Color(0xFF33C3AC);
  static const Color primaryDark = Color(0xFF267B61);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF314158);
  static const Color secondaryLight = Color(0xFF45556C);
  static const Color secondaryDark = Color(0xFF1D293D);
  
  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1D293D);
  static const Color textSecondary = Color(0xFF62748E);
  static const Color textTertiary = Color(0xFF717182);
  static const Color textLight = Color(0xFF90A1B9);
  
  // Input Colors
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputIcon = Color(0xFF90A1B9);
  
  // Status Colors
  static const Color success = Color(0xFF00BC7D);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFFE9A00);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  
  // Rating Color
  static const Color rating = Color(0xFFFE9A00);
  static const Color ratingText = Color(0xFFBB4D00);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF33C3AC), Color(0xFF314158)],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF32C7AC), Color(0xFF1D293D)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );
  
  // Avatar Colors
  static const Color avatarBackground = Color(0xFFC5FFF4);
  static const Color avatarText = Color(0xFF267B61);
  
  // Card Colors
  static const Color cardIconBg1 = Color(0x62C6AFA6); // rgba(98, 198, 175, 0.65)
  static const Color cardIconBg2 = Color(0xFF3D8679);
  static const Color cardIconBg3 = Color(0xBA4BA486); // rgba(75, 164, 134, 0.73)
  
  // Border Color
  static const Color border = Color(0xFFE2E8F0);
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.125,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.textSecondary,
  );
  
  // Labels
  static const TextStyle label = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 0.875,
    color: AppColors.secondary,
  );
  
  static const TextStyle labelLight = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 0.875,
    color: AppColors.secondary,
  );
  
  // Button Text
  static const TextStyle button = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1,
    color: Colors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: Colors.white,
  );
  
  // Input Hint
  static const TextStyle inputHint = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.125,
    color: AppColors.textTertiary,
  );
  
  // Input Text
  static const TextStyle input = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.125,
    color: AppColors.textPrimary,
  );
  
  // Link Text
  static const TextStyle link = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.primary,
  );
  
  // Splash Screen
  static const TextStyle splashTitle = TextStyle(
    fontFamily: 'Arima',
    fontSize: 48,
    fontWeight: FontWeight.w400,
    height: 1,
    letterSpacing: -1.2,
    color: Colors.white,
  );
  
  static const TextStyle splashSubtitle = TextStyle(
    fontFamily: 'Arima',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.625,
    color: Color(0xE6FFFFFF), // rgba(255, 255, 255, 0.9)
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Arimo',
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h3,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.inputBorder, width: 2),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        hintStyle: AppTextStyles.inputHint,
      ),
      
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}