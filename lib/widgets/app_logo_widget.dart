import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometric Hexagon Logo Widget matching media_1789140159280.jpg
class HexagonLogoWidget extends StatelessWidget {
  final double size;
  final String? badgeText;
  final bool showContainer;

  const HexagonLogoWidget({
    super.key,
    this.size = 120,
    this.badgeText,
    this.showContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size;
    final innerIconSize = logoSize * 0.52;

    Widget logoContent = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Interlocking Geometric Hexagon Custom Painter
        SizedBox(
          width: innerIconSize,
          height: innerIconSize,
          child: CustomPaint(
            painter: _HexagonIconPainter(),
          ),
        ),

        // Notification Badge (e.g. '4') if specified
        if (badgeText != null)
          Positioned(
            top: -logoSize * 0.08,
            right: -logoSize * 0.08,
            child: Container(
              padding: EdgeInsets.all(logoSize * 0.06),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x99EF4444),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: logoSize * 0.26,
                minHeight: logoSize * 0.26,
              ),
              child: Center(
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: logoSize * 0.13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (!showContainer) return logoContent;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(logoSize * 0.26),
        border: Border.all(
          color: const Color(0xFF38BDF8).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          // Dark ambient elevation
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          // Bottom cyan ambient aura glow
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: logoContent),
    );
  }
}

class _HexagonIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // White to Cyan gradient
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFE0F2FE),
        Color(0xFF38BDF8),
        Color(0xFF2563EB),
      ],
      stops: [0.0, 0.5, 0.8, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Inner folded chevron accents
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.9);

    final innerPath = Path();
    final innerRadius = radius * 0.55;
    for (int i = 0; i < 6; i += 2) {
      final a1 = (i * 60 - 30) * math.pi / 180;
      final a2 = ((i + 1) * 60 - 30) * math.pi / 180;

      final x1 = center.dx + innerRadius * math.cos(a1);
      final y1 = center.dy + innerRadius * math.sin(a1);
      final x2 = center.dx + innerRadius * math.cos(a2);
      final y2 = center.dy + innerRadius * math.sin(a2);

      innerPath.moveTo(x1, y1);
      innerPath.lineTo(x2, y2);
    }
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
