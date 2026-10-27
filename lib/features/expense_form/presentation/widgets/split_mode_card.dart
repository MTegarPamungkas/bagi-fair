import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplitModeCard extends StatelessWidget {
  const SplitModeCard({super.key, required this.state});

  final ExpenseFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = switch (state.splitMode) {
      SplitMode.equal => l10n.splitModeEqualHint,
      SplitMode.percentage => l10n.splitModePercentageHint,
      SplitMode.exact => l10n.splitModeExactHint,
      SplitMode.itemized => l10n.splitModeItemizedHint,
    };
    return FairCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.splitMode.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
                ),
              ),
              Pill(
                label: l10n.splitModeName(state.splitMode),
                selected: true,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 6) / 2;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final mode in SplitMode.values)
                    SizedBox(
                      width: width,
                      child: SplitModeTile(
                        mode: mode,
                        selected: state.splitMode == mode,
                        onTap: () => context.read<ExpenseFormBloc>().add(
                          ExpenseFormModeChanged(mode),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(hint, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

/// One selectable split mode. Readable without colour: the icon, label and
/// short hint all change together.
class SplitModeTile extends StatelessWidget {
  const SplitModeTile({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final SplitMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final l10n = context.l10n;
    final icon = switch (mode) {
      SplitMode.equal => Icons.balance_rounded,
      SplitMode.percentage => Icons.percent_rounded,
      SplitMode.exact => Icons.edit_rounded,
      SplitMode.itemized => Icons.receipt_long_rounded,
    };
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? fair.accentSoft : fair.surfaceMuted,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: selected ? fair.accent : fair.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? fair.accent : fair.inkMuted,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                l10n.splitModeName(mode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelLarge?.copyWith(
                  fontSize: 12,
                  color: selected ? fair.ink : fair.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
