import 'package:flutter/material.dart';

// Brand anchors
const zPurple = Color(0xFF2C015D);
const zPink = Color(0xFFFF3D7F);

// Use tertiary as your "trophy yellow"
const zTrophyYellow = Color(0xFFFFC107);

// ---------------------------
// LIGHT
// ---------------------------
final ColorScheme zLightScheme = ColorScheme(
  brightness: Brightness.light,

  primary: zPurple,
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFECE7F6),
  onPrimaryContainer: zPurple,

  secondary: zPink,
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFFFE6F0),
  onSecondaryContainer: const Color(0xFF5A0022),

  tertiary: zTrophyYellow,
  onTertiary: const Color(0xFF2A1A00),
  tertiaryContainer: const Color(0xFFFFF4D6),
  onTertiaryContainer: const Color(0xFF2A1A00),

  error: const Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: const Color(0xFFF9DEDC),
  onErrorContainer: const Color(0xFF410E0B),

  background: const Color(0xFFF5F3FC),
  onBackground: const Color(0xFF1C1B1F),

  surface: const Color(0xFFF5F3FC),
  onSurface: const Color(0xFF1C1B1F),

  surfaceVariant: const Color(0xFFE7E0EC),
  onSurfaceVariant: const Color(0xFF49454F),

  outline: const Color(0xFF7A7284),
  outlineVariant: const Color(0xFFCBBFD6),

  shadow: const Color(0xFF000000),
  scrim: const Color(0xFF000000),

  inverseSurface: const Color(0xFF322F35),
  onInverseSurface: const Color(0xFFF6F0FA),
  inversePrimary: const Color(0xFFDCCBFF),
);

// ---------------------------
// DARK (UPDATED)
// ---------------------------
final ColorScheme zDarkScheme = ColorScheme(
  brightness: Brightness.dark,

  primary: const Color(0xFFE9DDFF),
  onPrimary: zPurple,

  primaryContainer: zPurple,
  onPrimaryContainer: const Color(0xFFF5F0FF),

  secondary: const Color(0xFFFF5C98),
  onSecondary: const Color(0xFF2A0012),

  secondaryContainer: const Color(0xFF5A0022),
  onSecondaryContainer: const Color(0xFFFFE6F0),

  tertiary: const Color(0xFFFFD36B),
  onTertiary: const Color(0xFF2A1A00),
  tertiaryContainer: const Color(0xFF3D2E00),
  onTertiaryContainer: const Color(0xFFFFF0C2),

  error: const Color(0xFFF2B8B5),
  onError: const Color(0xFF601410),
  errorContainer: const Color(0xFF8C1D18),
  onErrorContainer: const Color(0xFFF9DEDC),

  // ✅ Make background darker
  background: const Color(0xFF0B0A10),
  onBackground: const Color(0xFFF3EFF7),

  // ✅ Make surfaces (cards/buttons) noticeably lighter than background
  surface: const Color(0xFF16131C),
  onSurface: const Color(0xFFF3EFF7),

  // ✅ Make surfaceVariant lighter too (used by many widgets)
  surfaceVariant: const Color(0xFF3A3346),
  onSurfaceVariant: const Color(0xFFD6CBE4),

  outline: const Color(0xFF9A8FA8),
  outlineVariant: const Color(0xFF51485F),

  shadow: const Color(0xFF000000),
  scrim: const Color(0xFF000000),

  inverseSurface: const Color(0xFFF3EFF7),
  onInverseSurface: const Color(0xFF1B1820),
  inversePrimary: zPurple,
);

