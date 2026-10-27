import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:flutter/material.dart';

IconData categoryIcon(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => Icons.restaurant_rounded,
  ExpenseCategory.transport => Icons.directions_car_filled_rounded,
  ExpenseCategory.stay => Icons.hotel_rounded,
  ExpenseCategory.groceries => Icons.shopping_basket_rounded,
  ExpenseCategory.utilities => Icons.bolt_rounded,
  ExpenseCategory.fun => Icons.celebration_rounded,
  ExpenseCategory.shopping => Icons.shopping_bag_rounded,
  ExpenseCategory.other => Icons.receipt_long_rounded,
};

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    required this.payerName,
    this.groupName,
    this.yourShareMinor,
    this.onTap,
    this.onDelete,
    this.showGroup = false,
    this.flat = false,
  });

  final Expense expense;

  /// Group base currency; amounts may still be displayed in the original one.
  final String currency;
  final String payerName;
  final String? groupName;
  final int? yourShareMinor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showGroup;

  /// Renders as a row without its own card, for use inside a ledger list.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    final body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: fair.surfaceMuted,
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              categoryIcon(expense.category),
              size: 19,
              color: fair.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AmountText(
                      minor: expense.amountMinor,
                      currency: expense.currency,
                      localeCode: locale,
                      compact: true,
                      style: context.texts.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (showGroup && groupName != null) groupName!,
                    '${l10n.paidByLower} $payerName',
                    AppDates.short(expense.occurredAt, localeCode: locale),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    Pill(
                      label: l10n.splitModeName(expense.splitMode),
                      dense: true,
                    ),
                    if (expense.currency != currency)
                      Pill(
                        label: '${expense.currency} · ${expense.fxRate}',
                        dense: true,
                        icon: Icons.currency_exchange_rounded,
                      ),
                    if (yourShareMinor != null)
                      Pill(
                        label:
                            '${l10n.yourShare}: ${_shareLabel(locale, yourShareMinor!, currency)}',
                        dense: true,
                        selected: true,
                      ),
                    if (expense.isPending)
                      Pill(
                        label: l10n.pendingSync,
                        dense: true,
                        icon: Icons.cloud_upload_outlined,
                        tone: fair.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.more_vert_rounded, size: 18),
            ),
        ],
    );

    if (flat) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: body,
        ),
      );
    }
    return FairCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: body,
    );
  }

  String _shareLabel(String locale, int minor, String currency) {
    return MoneyFormatter.format(minor, currency: currency, localeCode: locale);
  }
}
