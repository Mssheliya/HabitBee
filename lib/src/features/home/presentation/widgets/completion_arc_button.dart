import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular completion button with frequency-based arc ring.
///
/// - The outer ring is split into [frequency] equal arcs.
/// - [completionCount] arcs appear filled with [color]; the rest are
///   subtle outlines. Filling animates smoothly.
/// - Between the inner circle and the arc ring there is a clear 3px gap.
/// - When fully completed, the inner circle fills with [color] and shows ✓.
class CompletionArcButton extends StatelessWidget {
  final Color color;
  final Color mutedColor;
  final int completionCount;
  final int frequency;
  final bool isCompleted;
  final bool isBusy;
  final VoidCallback? onTap;
  final double size;

  const CompletionArcButton({
    super.key,
    required this.color,
    required this.mutedColor,
    required this.completionCount,
    required this.frequency,
    required this.isCompleted,
    required this.isBusy,
    required this.onTap,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    const double ringGap = 3.0;
    const double ringStroke = 3.5;
    final double innerSize = size - (ringStroke + ringGap) * 2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Deep muted fill in every state; vibrant color stays on
                // the count text / check icon and the arc ring.
                color: mutedColor,
              ),
              child: Center(
                child: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : isCompleted
                        ? Icon(Icons.check_rounded,
                            color: color, size: 22)
                        : completionCount > 0
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  '$completionCount',
                                  key: ValueKey(completionCount),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              )
                            : Icon(Icons.check_rounded,
                                color: color.withValues(alpha: 0.35),
                                size: 20),
              ),
            ),

            // Outer frequency arc ring
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: completionCount.toDouble(),
                  end: isCompleted
                      ? frequency.toDouble()
                      : completionCount.toDouble(),
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, animatedCount, child) {
                  return CustomPaint(
                    painter: _FrequencyArcPainter(
                      filledArcs: animatedCount,
                      totalArcs: frequency,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyArcPainter extends CustomPainter {
  /// Fractional count for smooth fill animation (e.g. 1.6 = 1 full + 60% of 2nd).
  final double filledArcs;
  final int totalArcs;
  final Color color;

  _FrequencyArcPainter({
    required this.filledArcs,
    required this.totalArcs,
    required this.color,
  });

  static const double _gapAngle = 0.22; // gap between arc segments (radians)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 3.5;
    final radius = size.width / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final count = totalArcs.clamp(1, 24);
    final segmentAngle = (2 * math.pi - _gapAngle * count) / count;

    final emptyPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final filledPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    double start = -math.pi / 2 + _gapAngle / 2;
    for (var i = 0; i < count; i++) {
      final fillFraction = (filledArcs - i).clamp(0.0, 1.0);
      // Always draw the empty outline arc first
      canvas.drawArc(rect, start, segmentAngle, false, emptyPaint);
      // Then the filled portion on top
      if (fillFraction > 0) {
        canvas.drawArc(
            rect, start, segmentAngle * fillFraction, false, filledPaint);
      }
      start += segmentAngle + _gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyArcPainter oldDelegate) {
    return oldDelegate.filledArcs != filledArcs ||
        oldDelegate.totalArcs != totalArcs ||
        oldDelegate.color != color;
  }
}
