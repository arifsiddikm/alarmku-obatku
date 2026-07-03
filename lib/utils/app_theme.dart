import 'package:flutter/material.dart';

class AppTheme {
  // Warm cream & terracotta palette
  static const Color cream = Color(0xFFF5F0E8);
  static const Color creamDark = Color(0xFFEDE5D5);
  static const Color terracotta = Color(0xFFC17A5A);
  static const Color terracottaDark = Color(0xFFA8623F);
  static const Color terracottaLight = Color(0xFFE8A882);
  static const Color sage = Color(0xFF7A9E7E);
  static const Color sageDark = Color(0xFF5C7D60);
  static const Color sageLight = Color(0xFFB2CDAD);
  static const Color warmBrown = Color(0xFF4A3728);
  static const Color warmGray = Color(0xFF8C7B6B);
  static const Color warmGrayLight = Color(0xFFD4C8BC);
  static const Color white = Color(0xFFFFFBF7);
  static const Color error = Color(0xFFD64B3B);
  static const Color warning = Color(0xFFE8A500);
  static const Color surface = Color(0xFFFFFFFF);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.light(
        primary: terracotta,
        onPrimary: white,
        secondary: sage,
        onSecondary: white,
        surface: surface,
        onSurface: warmBrown,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: warmBrown,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: warmBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: warmGrayLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: warmGrayLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: TextStyle(color: warmGray.withOpacity(0.6), fontSize: 14),
        labelStyle: const TextStyle(color: warmGray, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: terracotta,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: warmGrayLight.withOpacity(0.5)),
        ),
      ),
      dividerTheme: DividerThemeData(color: warmGrayLight.withOpacity(0.5), thickness: 1),
    );
  }
}

class AppText {
  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.warmBrown, letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.warmBrown, letterSpacing: -0.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.warmBrown,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.warmBrown,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.warmGray,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.warmGray,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.warmBrown,
  );
}
