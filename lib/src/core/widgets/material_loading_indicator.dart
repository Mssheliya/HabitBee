import 'package:flutter/material.dart';
import 'dart:math' show cos, sin;

/// A beautiful Material UI loading indicator with multiple animation styles
class MaterialLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final LoadingStyle style;
  final String? message;

  const MaterialLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.style = LoadingStyle.pulse,
    this.message,
  });

  @override
  State<MaterialLoadingIndicator> createState() => _MaterialLoadingIndicatorState();
}

enum LoadingStyle {
  pulse,
  rotatingDots,
  wave,
  bouncing,
}

class _MaterialLoadingIndicatorState extends State<MaterialLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildIndicator(indicatorColor),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: indicatorColor.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicator(Color color) {
    switch (widget.style) {
      case LoadingStyle.pulse:
        return _buildPulseIndicator(color);
      case LoadingStyle.rotatingDots:
        return _buildRotatingDotsIndicator(color);
      case LoadingStyle.wave:
        return _buildWaveIndicator(color);
      case LoadingStyle.bouncing:
        return _buildBouncingIndicator(color);
    }
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseValue = 0.5 + 0.5 * (1 + (_controller.value * 2 - 1).abs());
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: widget.size * pulseValue,
              height: widget.size * pulseValue,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: widget.size * 0.7 * pulseValue,
              height: widget.size * 0.7 * pulseValue,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 2,
                ),
              ),
            ),
            // Center dot
            Container(
              width: widget.size * 0.3,
              height: widget.size * 0.3,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRotatingDotsIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final adjustedValue = (_controller.value + delay) % 1.0;
            final angle = adjustedValue * 2 * 3.14159;
            final radius = widget.size * 0.3;
            
            return Transform.translate(
              offset: Offset(
                radius * cos(angle),
                radius * sin(angle),
              ),
              child: Container(
                width: widget.size * 0.2,
                height: widget.size * 0.2,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6 + 0.4 * sin(adjustedValue * 3.14159)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final adjustedValue = (_controller.value + delay) % 1.0;
            final scale = 0.5 + 0.5 * sin(adjustedValue * 3.14159);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
              width: widget.size * 0.2,
              height: widget.size * (0.3 + 0.4 * scale),
              decoration: BoxDecoration(
                color: color.withOpacity(0.5 + 0.5 * scale),
                borderRadius: BorderRadius.circular(widget.size * 0.1),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBouncingIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating outer ring
            RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Bouncing dots
            ...List.generate(2, (index) {
              final delay = index * 0.5;
              final adjustedValue = (_controller.value + delay) % 1.0;
              final bounce = sin(adjustedValue * 3.14159);
              
              return Transform.translate(
                offset: Offset(
                  (index == 0 ? -1 : 1) * widget.size * 0.25,
                  -bounce * widget.size * 0.2,
                ),
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.15,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7 + 0.3 * bounce),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// A shimmer loading effect for cards and lists
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double progress;

  const _SlidingGradientTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (progress * 2 - 0.5),
      0,
      0,
    );
  }
}
