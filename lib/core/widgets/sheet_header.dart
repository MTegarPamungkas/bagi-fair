import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: fair.accentSoft,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: fair.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 20, color: fair.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.texts.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
