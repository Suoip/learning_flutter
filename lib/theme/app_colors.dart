import 'package:flutter/material.dart';

/// Notes app's dark, "playful & rounded" color scheme — a single vivid
/// blurple accent over dark blue-gray neutrals. Hand-specified rather than
/// [ColorScheme.fromSeed] so the neutrals stay flat (no HCT surface-tint
/// wash) and pixel-exact to the approved design mockup.
const ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.dark,

  primary: Color(0xFF5865F2),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFF3D4489),
  onPrimaryContainer: Color(0xFFE3E5FF),

  secondary: Color(0xFFB8BCE6),
  onSecondary: Color(0xFF1F2340),
  secondaryContainer: Color(0xFF2E3350),
  onSecondaryContainer: Color(0xFFDEE0FF),

  tertiary: Color(0xFF4FD1A5),
  onTertiary: Color(0xFF00382A),
  tertiaryContainer: Color(0xFF1E4A3D),
  onTertiaryContainer: Color(0xFFB6F5DE),

  // Flutter/M3's own vetted dark-scheme error ramp, already contrast-tested.
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),

  surface: Color(0xFF1E2128),
  onSurface: Color(0xFFE3E5E8),
  surfaceDim: Color(0xFF101217),
  surfaceBright: Color(0xFF383D4A),
  surfaceContainerLowest: Color(0xFF15171C),
  surfaceContainerLow: Color(0xFF191C22),
  surfaceContainer: Color(0xFF20232B),
  surfaceContainerHigh: Color(0xFF262A33),
  surfaceContainerHighest: Color(0xFF2D323D),
  onSurfaceVariant: Color(0xFF8A8F98),

  outline: Color(0xFF63697A),
  outlineVariant: Color(0xFF33363F),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFE3E5E8),
  onInverseSurface: Color(0xFF1E2128),
  inversePrimary: Color(0xFF5865F2),

  // Disables Material 3's automatic surface-tint wash on elevated surfaces,
  // which would otherwise blend a purple cast across every card/app bar.
  surfaceTint: Colors.transparent,
);

/// Feature-specific colors that don't map onto a generic [ColorScheme] role.
class AppColors {
  const AppColors._();

  /// Favorite/star icon color — kept a distinct gold rather than folded
  /// into [appColorScheme.primary], since "star = gold" is too strong a
  /// universal convention to break.
  static const Color favoriteAccent = Color(0xFFFFC24B);

  /// Small notification badge dot. [appColorScheme.error] is a pale pink
  /// tuned for large containers and reads washed-out at badge sizes.
  static const Color notificationDot = Color(0xFFEF4444);
}
