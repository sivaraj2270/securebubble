import 'package:flutter/material.dart';
import '../main.dart';

class ZentraTheme {
  static bool get isDark => themeNotifier.value == ThemeMode.dark;

  // Dynamic Colors based on active themeMode
  static Color get background => isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9);
  static Color get surfaceCard => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  static Color get surfaceBorder => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // Royal Blue & Primary Accents
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Status Colors
  static const Color safeGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Dynamic Text Colors
  static Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Ambient Background that reacts dynamically to Light/Dark Mode
  static Widget buildAmbientBackground({required Widget child}) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        return Stack(
          children: [
            Container(color: dark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9)),

            // Top Left Soft Aura
            Positioned(
              top: -120,
              left: -80,
              child: RepaintBoundary(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: dark
                          ? [
                              const Color(0x352563EB),
                              const Color(0x153B82F6),
                              const Color(0x00070A12),
                            ]
                          : [
                              const Color(0x252563EB),
                              const Color(0x103B82F6),
                              const Color(0x00F1F5F9),
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Right Soft Aura
            Positioned(
              bottom: -100,
              right: -60,
              child: RepaintBoundary(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: dark
                          ? [
                              const Color(0x253B82F6),
                              const Color(0x108B5CF6),
                              const Color(0x00070A12),
                            ]
                          : [
                              const Color(0x203B82F6),
                              const Color(0x082563EB),
                              const Color(0x00F1F5F9),
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(child: child),
          ],
        );
      },
    );
  }

  // Primary Royal Blue Button
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Dynamic Card Container (Adapts to Light / Dark Mode)
  static Widget buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    Color? borderColor,
  }) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? (dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: dark ? 0.4 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
