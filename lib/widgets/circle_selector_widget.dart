import 'package:flutter/material.dart';

class CircleSelectorWidget extends StatefulWidget {
  final Function(Rect selectedRect) onRegionSelected;
  final VoidCallback onCancel;

  const CircleSelectorWidget({
    super.key,
    required this.onRegionSelected,
    required this.onCancel,
  });

  @override
  State<CircleSelectorWidget> createState() => _CircleSelectorWidgetState();
}

class _CircleSelectorWidgetState extends State<CircleSelectorWidget> {
  final List<Offset> _points = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points.clear();
      _points.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_points.length < 5) return;

    double minX = _points.first.dx;
    double maxX = _points.first.dx;
    double minY = _points.first.dy;
    double maxY = _points.first.dy;

    for (final p in _points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    widget.onRegionSelected(rect);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: CustomPaint(
              painter: _CirclePainter(_points),
              size: Size.infinite,
            ),
          ),
        ),

        // Header Banner
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18102B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8B5CF6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "SecureBubble AI • Circle Anything to Scan",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final List<Offset> points;

  _CirclePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFA78BFA).withOpacity(0.4)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], glowPaint);
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) => true;
}
