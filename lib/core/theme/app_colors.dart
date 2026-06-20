import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A07E8); // Electric Purple
  static const Color primaryContainer = Color(0xFF633BFF);
  static const Color secondary = Color(0xFF00677F); // Cyan Blue
  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color border = Color(0xFFC9C3D9); // Outline variant
  static const Color borderSoft = Color(0xFFE2E7FF); // Surface container high
  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF484556);
  static const Color queuedBlue = Color(0xFF58A7E8);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF16A34A);

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF633BFF), Color(0xFF4A07E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF52C1), Color(0xFFFF9E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF4cd6ff), Color(0xFF00ccf9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF3CD5ED), Color(0xFF8CE158)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
