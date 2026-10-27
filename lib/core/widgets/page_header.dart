import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Page heading used inside the content area.
///
/// On narrow screens the actions move below the text instead of squeezing the
/// title into a one-word-per-line column.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.compact = false,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final width = MediaQuery.sizeOf(context).width - context.pagePadding * 2;
    final stackActions = width < 560 || compact;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null && eyebrow!.isNotEmpty) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              color: fair.accent,
              letterSpacing: 1.8,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: context.texts.headlineLarge?.copyWith(
            fontSize: compact ? 24 : 28,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(subtitle!, style: context.texts.bodyMedium),
          ),
        ],
      ],
    );

    if (actions.isEmpty && leading == null) return titleBlock;

    if (stackActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Row(
              children: [
                leading!,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: titleBlock),
              ],
            ),
          ] else
            titleBlock,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: actions),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(child: titleBlock),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: actions,
          ),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.overline,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final String? overline;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null && overline!.isNotEmpty) ...[
                Text(
                  overline!.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    color: fair.inkMuted,
                    fontSize: 9,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(title, style: context.texts.headlineSmall),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.texts.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
      ],
    );
  }
}
