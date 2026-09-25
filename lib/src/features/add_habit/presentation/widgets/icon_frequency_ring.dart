import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular icon button surrounded by animated frequency arc segments.
/// The number of arcs equals [frequency]; when frequency changes, the arcs
/// grow/shrink smoothly via [TweenAnimationBuilder].
class IconFrequencyRing extends StatelessWidget {
  final IconData icon;
  final int frequency;
  final int maxFrequency;
  final VoidCallback onTap;
  final double size;

  const IconFrequencyRing({
    super.key,
    required this.icon,
    required this.frequency,
    required this.onTap,
    this.maxFrequency = 10,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: frequency.toDouble(), end: frequency.toDouble()),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animatedFrequency, child) {
            return CustomPaint(
              painter: _FrequencyRingPainter(
                segments: animatedFrequency,
                maxSegments: maxFrequency,
                color: color,
                trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FrequencyRingPainter extends CustomPainter {
  /// Fractional segment count for smooth animation (e.g. 2.5 means 2 full
  /// arcs plus a half-grown third arc).
  final double segments;
  final int maxSegments;
  final Color color;
  final Color trackColor;

  _FrequencyRingPainter({
    required this.segments,
    required this.maxSegments,
    required this.color,
    required this.trackColor,
  });

  static const double _gapAngle = 0.28; // gap between segments (radians)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Faint full-circle track so the button always reads as a circle.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (segments <= 0) return;

    // Evenly distribute arcs around the circle with small gaps.
    final count = segments.floor().clamp(1, maxSegments);
    final segmentAngle = (2 * math.pi - _gapAngle * count) / count;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double start = -math.pi / 2 + _gapAngle / 2; // start at top
    for (var i = 0; i < count; i++) {
      double sweep = segmentAngle;
      // The newest segment grows in smoothly as the animation value rises
      // above the previous whole number.
      if (i == count - 1 && segments < count) {
        sweep = segmentAngle * (segments - (count - 1)).clamp(0.0, 1.0);
      }
      if (sweep > 0.001) {
        canvas.drawArc(rect, start, sweep, false, arcPaint);
      }
      start += segmentAngle + _gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
