import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A Material 3 circular theme preview widget that renders 3 colors:
/// - Top half: Primary color
/// - Bottom-left quadrant: Secondary color
/// - Bottom-right quadrant: Tertiary color
///
/// Automatically updates colors based on active [brightness] and [dynamicSchemeVariant].
class ThemeColorCircle extends StatelessWidget {
  final Color seedColor;
  final String? name;
  final bool isSelected;
  final VoidCallback onTap;
  final Brightness brightness;
  final DynamicSchemeVariant dynamicSchemeVariant;
  final double size;

  const ThemeColorCircle({
    super.key,
    required this.seedColor,
    this.name,
    required this.isSelected,
    required this.onTap,
    required this.brightness,
    required this.dynamicSchemeVariant,
    this.size = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    // Generate live Material 3 color scheme for this seed color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: dynamicSchemeVariant,
    );

    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final tertiaryColor = colorScheme.tertiary;

    // Shade direction depends on brightness:
    // Light mode: top half = light shade of primary, bottom = dark shades
    // Dark mode:  top half = dark shade of primary, bottom = light shades
    final bool isLight = brightness == Brightness.light;
    Color lighten(Color c, double amount) => Color.lerp(c, Colors.white, amount)!;
    Color darken(Color c, double amount) => Color.lerp(c, Colors.black, amount)!;

    final topColor = isLight
        ? lighten(primaryColor, 0.45)
        : darken(primaryColor, 0.35);
    final bottomLeftColor = isLight
        ? darken(secondaryColor, 0.25)
        : lighten(secondaryColor, 0.40);
    final bottomRightColor = isLight
        ? darken(tertiaryColor, 0.25)
        : lighten(tertiaryColor, 0.40);

    return Semantics(
      label: name != null ? '$name theme' : 'Theme color',
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: name ?? 'Theme color',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size),
            splashColor: primaryColor.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: isSelected ? 3 : 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(isSelected ? 3.0 : 2.0),
                  child: ClipOval(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _ThreeSplitColorPainter(
                          topColor: topColor,
                          bottomLeftColor: bottomLeftColor,
                          bottomRightColor: bottomRightColor,
                        ),
                      child: Center(
                        child: isSelected
                            ? Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                if (name != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: size + 16,
                    child: Text(
                      name!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeSplitColorPainter extends CustomPainter {
  final Color topColor;
  final Color bottomLeftColor;
  final Color bottomRightColor;

  _ThreeSplitColorPainter({
    required this.topColor,
    required this.bottomLeftColor,
    required this.bottomRightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);

    final topPaint = Paint()
      ..color = topColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bottomLeftPaint = Paint()
      ..color = bottomLeftColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bottomRightPaint = Paint()
      ..color = bottomRightColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Top Half (180 degrees from angle PI to 2*PI, i.e. 180° to 360°)
    canvas.drawArc(rect, math.pi, math.pi, true, topPaint);

    // Bottom-Left Quadrant (90 degrees from angle PI/2 to PI, i.e. 90° to 180°)
    canvas.drawArc(rect, math.pi / 2, math.pi / 2, true, bottomLeftPaint);

    // Bottom-Right Quadrant (90 degrees from angle 0 to PI/2, i.e. 0° to 90°)
    canvas.drawArc(rect, 0, math.pi / 2, true, bottomRightPaint);

    // Fine inner divider lines for high contrast sharpness
    final dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      dividerPaint,
    );

    // Bottom vertical line
    canvas.drawLine(
      center,
      Offset(center.dx, size.height),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThreeSplitColorPainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.bottomLeftColor != bottomLeftColor ||
        oldDelegate.bottomRightColor != bottomRightColor;
  }
}
