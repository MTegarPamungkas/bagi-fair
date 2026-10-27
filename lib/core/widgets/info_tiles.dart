import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Compact number tile. The label is monospace and allowed to shrink so
/// "Kamu ditagih" never becomes "KAMU DITAG…".
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.flat = false,
  });

  final String label;
  final Widget value;
  final IconData icon;
  final Color? tone;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = tone ?? fair.accent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: flat ? Colors.transparent : fair.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: fair.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 0.5,
                    color: fair.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: context.fair.inkMuted),
            const SizedBox(width: 7),
          ],
          Expanded(child: Text(label, style: context.texts.bodySmall)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.texts.titleSmall?.copyWith(
                color: valueColor,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
