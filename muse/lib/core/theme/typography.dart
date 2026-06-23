import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Glass Domain
  static TextTheme glassTextTheme = GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1.0),
    bodyLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500),
  );

  // Hardware Domain
  static TextStyle lcdDisplay = GoogleFonts.shareTechMono(
    color: Colors.black87,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
  );
  
  static TextStyle hardwareEngraving = GoogleFonts.inter(
    color: Colors.white38,
    fontWeight: FontWeight.w900,
    letterSpacing: 3.0,
    fontSize: 10,
  );
}