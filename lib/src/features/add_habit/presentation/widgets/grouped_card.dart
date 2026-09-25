import 'package:flutter/material.dart';

/// Position of a card inside a grouped list (Android settings style).
enum GroupedCardPosition { top, middle, bottom, single }

/// A Material card whose corner radius follows the Android native
/// grouped-list convention:
/// - top item: large top corners, small bottom corners
/// - middle items: small corners on all sides
/// - bottom item: small top corners, large bottom corners
class GroupedCard extends StatelessWidget {
  final Widget child;
  final GroupedCardPosition position;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  static const double outerRadius = 15.0;
  static const double innerRadius = 5.0;

  /// Tiny gap between items *inside* one grouped card stack,
  /// so the scaffold background subtly shows through (Android style).
  static const double innerGap = 2.0;

  /// Larger gap between two separate card groups.
  static const double groupGap = 16.0;

  const GroupedCard({
    super.key,
    required this.child,
    this.position = GroupedCardPosition.single,
    this.padding,
    this.onTap,
  });

  BorderRadius _radiusFor(GroupedCardPosition position) {
    switch (position) {
      case GroupedCardPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(outerRadius),
          topRight: Radius.circular(outerRadius),
          bottomLeft: Radius.circular(innerRadius),
          bottomRight: Radius.circular(innerRadius),
        );
      case GroupedCardPosition.middle:
        return const BorderRadius.all(Radius.circular(innerRadius));
      case GroupedCardPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(innerRadius),
          topRight: Radius.circular(innerRadius),
          bottomLeft: Radius.circular(outerRadius),
          bottomRight: Radius.circular(outerRadius),
        );
      case GroupedCardPosition.single:
        return const BorderRadius.all(Radius.circular(outerRadius));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = _radiusFor(position);

    // Matches the progress-page calendar background color logic
    final cardColor = theme.cardTheme.color ??
        (theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4));

    return Material(
      color: cardColor,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Builds several [GroupedCard]s as ONE visually grouped stack:
/// top/middle/bottom corner radii with a tiny [GroupedCard.innerGap]
/// between items so the scaffold background peeks through.
class GroupedCardsColumn extends StatelessWidget {
  final List<Widget> children;

  const GroupedCardsColumn({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: GroupedCard.innerGap),
          children[i],
        ],
      ],
    );
  }
}

/// Convenience: returns the correct [GroupedCardPosition] for an index.
GroupedCardPosition groupedPosition(int index, int total) {
  if (total == 1) return GroupedCardPosition.single;
  if (index == 0) return GroupedCardPosition.top;
  if (index == total - 1) return GroupedCardPosition.bottom;
  return GroupedCardPosition.middle;
}
