import 'package:flutter/material.dart';

class ZentraTheme {
  // Deep Midnight Obsidian Color Palette
  static const Color background = Color(0xFF070A12);
  static const Color surfaceCard = Color(0xFF0F172A);
  static const Color surfaceBorder = Color(0xFF1E293B);
  
  // Electric Blue & Cyan Accents
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFF8B5CF6);
  
  // Status Colors
  static const Color safeGreen = Color(0xFF4ADE80);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Zentra Glassmorphic Ambient Mesh Container
  static Widget buildAmbientBackground({required Widget child}) {
    return Stack(
      children: [
        Container(color: background),
        
        // Top Left Ambient Blue Aura Glow (RepaintBoundary cached for 60fps performance)
        Positioned(
          top: -100,
          left: -80,
          child: RepaintBoundary(
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x3B2563EB),
                    Color(0x1A38BDF8),
                    Color(0x00070A12),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Bottom Right Ambient Purple Aura Glow (RepaintBoundary cached)
        Positioned(
          bottom: -80,
          right: -60,
          child: RepaintBoundary(
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x308B5CF6),
                    Color(0x153B82F6),
                    Color(0x00070A12),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        SafeArea(child: child),
      ],
    );
  }

  // Zentra Action Button with Electric Blue Gradient
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Zentra Glass Card
  static Widget buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    Color? borderColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? surfaceBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
