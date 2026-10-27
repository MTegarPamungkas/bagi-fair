import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Section 1 of the expense form: what, how much, who paid, when, which bucket.
class ExpenseBasicsCard extends StatelessWidget {
  const ExpenseBasicsCard({
    super.key,
    required this.state,
    required this.controllers,
    required this.currentUserId,
  });

  final ExpenseFormState state;
  final ExpenseFormControllers controllers;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ExpenseFormBloc>();
    return FairCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('Untuk apa?', 'What was it for?').toUpperCase(),
            style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controllers.title,
            textInputAction: TextInputAction.next,
            onChanged: (value) => bloc.add(ExpenseFormTitleChanged(value)),
            decoration: InputDecoration(
              hintText: l10n.expenseTitleHint,
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers.amount,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final minor = MoneyFormatter.parse(
                      value,
                      currency: state.currency,
                    );
                    if (minor != null) {
                      bloc.add(ExpenseFormAmountChanged(minor));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    prefixText:
                        '${MoneyFormatter.symbolFor(state.currency)} ',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 104,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    final currency = await showCurrencyPicker(
                      context,
                      selected: state.currency,
                    );
                    if (currency != null && context.mounted) {
                      bloc.add(ExpenseFormCurrencyChanged(currency));
                    }
                  },
                  child: Text(
                    state.currency,
                    maxLines: 1,
                    style: context.texts.labelLarge,
                  ),
                ),
              ),
            ],
          ),
          if (state.isForeignCurrency) ...[
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: controllers.fx,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                final rate = double.tryParse(
                  value.replaceAll('.', '').replaceAll(',', '.'),
                );
                if (rate != null && rate > 0) {
                  bloc.add(ExpenseFormFxRateChanged(rate));
                }
              },
              decoration: InputDecoration(
                labelText: l10n.exchangeRate,
                hintText: l10n.fxHint,
                prefixIcon: const Icon(Icons.currency_exchange_rounded),
                helperText:
                    '1 ${state.currency} = ${_rateText(state.fxRate)} ${state.groupCurrency}',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: state.payerId,
            decoration: InputDecoration(
              labelText: l10n.paidBy,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            items: [
              for (final member in state.members)
                DropdownMenuItem(
                  value: member.userId,
                  child: Text(
                    member.userId == currentUserId
                        ? '${member.displayName} (${l10n.you})'
                        : member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) bloc.add(ExpenseFormPayerChanged(value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            borderRadius: AppRadius.allMd,
            onTap: () async {
              final date = await showFairDatePicker(
                context,
                initial: state.effectiveDate,
              );
              if (date != null && context.mounted) {
                bloc.add(ExpenseFormDateChanged(date));
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.date,
                prefixIcon: const Icon(Icons.event_outlined),
              ),
              child: Text(
                AppDates.medium(
                  state.effectiveDate,
                  localeCode: l10n.locale.languageCode,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.category.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final category in ExpenseCategory.values)
                Pill(
                  label: l10n.categoryName(category),
                  selected: state.category == category,
                  onTap: () => bloc.add(ExpenseFormCategoryChanged(category)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controllers.note,
            maxLines: 2,
            onChanged: (value) => bloc.add(ExpenseFormNoteChanged(value)),
            decoration: InputDecoration(
              labelText: l10n.note,
              hintText: l10n.noteHint,
            ),
          ),
        ],
      ),
    );
  }

  String _rateText(double rate) {
    if (rate == rate.roundToDouble()) return rate.toStringAsFixed(0);
    return rate.toString();
  }
}
