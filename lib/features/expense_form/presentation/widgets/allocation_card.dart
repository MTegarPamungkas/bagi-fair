import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Percentage and exact-amount allocation. Uses the same row rhythm as the
/// itemized editor so switching modes does not feel like a different form.
class AllocationCard extends StatelessWidget {
  const AllocationCard({
    super.key,
    required this.state,
    required this.controllers,
  });

  final ExpenseFormState state;
  final ExpenseFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ExpenseFormBloc>();
    if (state.participantIds.isEmpty) {
      return FairCard(
        child: Text(l10n.participantRequired, style: context.texts.bodyMedium),
      );
    }
    final weightTotal = state.weightsBps.values.fold(0, (a, b) => a + b);
    final exactTotal = state.exactMinor.values.fold(0, (a, b) => a + b);
    final isPercent = state.splitMode == SplitMode.percentage;
    final isExact = state.splitMode == SplitMode.exact;

    return FairCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPercent) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.percentage.toUpperCase(),
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                TotalBadge(
                  label: MoneyFormatter.percent(
                    weightTotal / 10000,
                    localeCode: l10n.locale.languageCode,
                  ),
                  valid: weightTotal == 10000,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final id in state.participantIds)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    AvatarCircle(name: state.nameFor(id), size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.nameFor(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: controllers.percent[id],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          suffixText: '%',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final percent = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (percent != null) {
                            bloc.add(
                              ExpenseFormWeightChanged(
                                id,
                                (percent * 100).round(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ] else if (isExact) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.exact.toUpperCase(),
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                TotalBadge(
                  label: MoneyFormatter.format(
                    exactTotal,
                    currency: state.currency,
                    localeCode: l10n.locale.languageCode,
                  ),
                  valid: exactTotal == state.amountMinor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final id in state.participantIds)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    AvatarCircle(name: state.nameFor(id), size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.nameFor(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: controllers.exact[id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: InputDecoration(
                          prefixText:
                              '${MoneyFormatter.symbolFor(state.currency)} ',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final minor = MoneyFormatter.parse(
                            value,
                            currency: state.currency,
                          );
                          if (minor != null) {
                            bloc.add(ExpenseFormExactChanged(id, minor));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ] else
            Text(l10n.splitModeEqualHint, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

class TotalBadge extends StatelessWidget {
  const TotalBadge({super.key, required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final tone = valid ? context.fair.positive : context.fair.negative;
    return Pill(
      label: label,
      selected: valid,
      tone: tone,
      icon: valid ? Icons.check_rounded : Icons.error_outline_rounded,
      dense: true,
    );
  }
}
