import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A segmented circular progress icon inspired by MUI DonutLarge,
/// with soft, rounded segment ends instead of sharp perpendicular edges.
class SegmentedDonutIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SegmentedDonutIcon({
    super.key,
    this.size = 24.0,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SegmentedDonutPainter(color: color),
      ),
    );
  }
}

class _SegmentedDonutPainter extends CustomPainter {
  final Color color;

  _SegmentedDonutPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    const toRad = math.pi / 180;

    // Left semicircle (approx 150 degrees)
    canvas.drawArc(rect, 105 * toRad, 150 * toRad, false, paint);

    // Top-right segment from 291° to 339° (sweep: 48°)
    canvas.drawArc(rect, 291 * toRad, 48 * toRad, false, paint);

    // Bottom-right segment from 21° to 69° (sweep: 48°)
    canvas.drawArc(rect, 21 * toRad, 48 * toRad, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SegmentedDonutPainter oldDelegate) =>
      oldDelegate.color != color;
}
