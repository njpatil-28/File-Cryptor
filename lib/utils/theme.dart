import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel color palette
  static const Color mintGreen = Color(0xFFE8F5E9);
  static const Color peach = Color(0xFFFFF3E0);
  static const Color lavender = Color(0xFFF3E5F5);
  static const Color skyBlue = Color(0xFFE1F5FE);
  static const Color primary = Color(0xFF81C784);
  static const Color secondary = Color(0xFFFFB74D);
  static const Color accent = Color(0xFFBA68C8);
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardColor = Color(0xFFFFFFFF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: background,
      background: background,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: background,
      foregroundColor: Colors.black87,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  );
}
