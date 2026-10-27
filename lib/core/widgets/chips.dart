import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A compact filter / meta chip.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.tone,
    this.selected = false,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? tone;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = tone ?? (selected ? fair.accent : fair.inkMuted);
    final background = selected ? fair.accentSoft : fair.surface;
    final content = Container(
      constraints: BoxConstraints(minHeight: dense ? 26 : 30),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 11,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allPill,
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.55) : fair.line,
          width: selected ? 1.4 : 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: color,
              fontSize: dense ? 10 : 11,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: AppRadius.allPill,
      onTap: onTap,
      child: content,
    );
  }
}

/// A rubber stamp. Used for "Impas" and other terminal states, because a
/// settled bill should feel *closed*, not just "green text".
class StampBadge extends StatelessWidget {
  const StampBadge({
    super.key,
    required this.label,
    this.tone,
    this.icon,
    this.angle = -0.07,
  });

  final String label;
  final Color? tone;
  final IconData? icon;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = tone ?? fair.stamp;
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                color: color,
                fontFamily: AppTypography.mono,
                fontSize: 9,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small monospace label + value pair used inside receipts.
class MetaPair extends StatelessWidget {
  const MetaPair({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            fontSize: 8.5,
            letterSpacing: 1.2,
            color: fair.inkMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: context.texts.titleSmall?.copyWith(
            color: valueColor ?? fair.ink,
            fontFeatures: AppTypography.tabular,
          ),
        ),
      ],
    );
  }
}
