import 'package:flutter/material.dart';

class AppColors {
  // Global Base
  static const Color background = Colors.black;
  static const Color pureWhite = Colors.white;

  // Domain Expansion : Glassy Sky
  static final Color glassShell = Colors.white.withOpacity(0.08);
  static final Color glassBorder = Colors.white.withOpacity(0.1);
  static final Color glassTextMuted = Colors.white54;
  
  // Domain Expansion : Wal-kuh-mano
  static const Color hardwareSurface = Color(0xFF1E2124);
  static const Color hardwareSurfaceDepressed = Color(0xFF3E4249);
  static const Color hardwareBorder = Colors.black87;
  static final Color ledRedActive = Colors.red.shade500;
  static final Color ledRedStandby = Colors.red.shade900;
  static const Color tapeSticker = Color(0xFFDED9C4);
}