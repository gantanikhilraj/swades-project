import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color neonGreen = Color(0xFF00FF87);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color neonCyan = Color(0xFF60EFFF);
  static const Color royalBlue = Color(0xFF3B82F6);
  
  // Slate Scale (Neutral Dark Colors)
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A); // Main background
  static const Color slate800 = Color(0xFF1E293B); // Surface / Cards
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  
  // Neutral Light Colors
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  
  // Shared Screen Background Gradient (Splash & Login)
  static const List<Color> darkBackgroundGradient = [
    slate900,
    slate800,
  ];

  static const LinearGradient darkScreenGradient = LinearGradient(
    colors: darkBackgroundGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: emeraldGreen,
      scaffoldBackgroundColor: slate50,
      colorScheme: const ColorScheme.light(
        primary: emeraldGreen,
        secondary: royalBlue,
        surface: Colors.white,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: slate900,
        ),
        iconTheme: IconThemeData(color: slate900),
      ),
      useMaterial3: true,
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonGreen,
      scaffoldBackgroundColor: slate900,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: royalBlue,
        surface: slate800,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: slate800,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }
}
