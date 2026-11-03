import 'package:flutter/material.dart';

/// Tema visual ala "Permet" — cahaya/partikel di ruang gelap.
/// Gelap, tenang, pendar lembut. TANPA warna panik, tanpa merah urgensi.
class AppTheme {
  const AppTheme._();

  // Palet: ruang gelap kebiruan + pendar cyan/ungu partikel.
  static const _bg = Color(0xFF0B0E14);
  static const _surface = Color(0xFF141925);
  static const _surfaceHi = Color(0xFF1D2434);
  static const _glow = Color(0xFF7FE7E0); // pendar jembatan (cyan lembut)
  static const _glowAlt = Color(0xFFB9A7F5); // ungu partikel
  static const _textHi = Color(0xFFECEFF4);
  static const _textLo = Color(0xFF9AA3B2);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _glow,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _bg,
      primary: _glow,
      secondary: _glowAlt,
      onSurface: _textHi,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _textHi, height: 1.4),
        bodyMedium: TextStyle(color: _textHi, height: 1.4),
        bodySmall: TextStyle(color: _textLo),
        titleMedium: TextStyle(color: _textHi, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _textHi,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardColor: _surface,
    );
  }

  // Token warna yang dipakai widget lain.
  static const Color bubbleUser = _surfaceHi;
  static const Color bubbleDia = _surface;
  static const Color glow = _glow;
  static const Color glowAlt = _glowAlt;
  static const Color textHi = _textHi;
  static const Color textLo = _textLo;
  static const Color background = _bg;
}
