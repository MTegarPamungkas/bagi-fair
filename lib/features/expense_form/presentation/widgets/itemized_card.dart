import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Per-item split: line items, who ate what, then tax/service/discount.
class ItemizedCard extends StatelessWidget {
  const ItemizedCard({
    super.key,
    required this.state,
    required this.controllers,
  });

  final ExpenseFormState state;
  final ExpenseFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    final bloc = context.read<ExpenseFormBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FairCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.receiptItems,
                subtitle: l10n.assignHint,
                action: TextButton.icon(
                  onPressed: () => bloc.add(const ExpenseFormItemAdded()),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(l10n.addItem),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.items.isEmpty)
                Text(l10n.itemsRequired, style: context.texts.bodySmall),
              for (final item in state.items) ...[
                ItemEditor(
                  item: item,
                  state: state,
                  controllers:
                      controllers.items[item.id] ?? ItemControllers(),
                  onChanged: bloc.add,
                  onRemove: () => bloc.add(ExpenseFormItemRemoved(item.id)),
                ),
                if (item != state.items.last)
                  Divider(
                    height: AppSpacing.lg,
                    color: context.fair.line,
                  ),
              ],
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoRow(
                  label: l10n.subtotal,
                  value: MoneyFormatter.format(
                    state.itemsSubtotalMinor,
                    currency: state.currency,
                    localeCode: locale,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FairCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.splitTaxService.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _moneyField(
                      context,
                      controller: controllers.tax,
                      label: l10n.tax,
                      currency: state.currency,
                      onChanged: (minor) =>
                          bloc.add(ExpenseFormTaxChanged(minor)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _moneyField(
                      context,
                      controller: controllers.service,
                      label: l10n.service,
                      currency: state.currency,
                      onChanged: (minor) =>
                          bloc.add(ExpenseFormServiceChanged(minor)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _moneyField(
                      context,
                      controller: controllers.discount,
                      label: l10n.discount,
                      currency: state.currency,
                      onChanged: (minor) =>
                          bloc.add(ExpenseFormDiscountChanged(minor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.splitModeItemizedHint, style: context.texts.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moneyField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String currency,
    required ValueChanged<int> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixText: '${MoneyFormatter.symbolFor(currency)} ',
      ),
      onChanged: (value) {
        final minor = MoneyFormatter.parse(value, currency: currency);
        if (minor != null) onChanged(minor);
      },
    );
  }
}

class ItemEditor extends StatelessWidget {
  const ItemEditor({
    super.key,
    required this.item,
    required this.state,
    required this.controllers,
    required this.onChanged,
    required this.onRemove,
  });

  final ExpenseItem item;
  final ExpenseFormState state;
  final ItemControllers controllers;
  final ValueChanged<ExpenseFormEvent> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final locale = l10n.locale.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers.name,
                decoration: InputDecoration(
                  labelText: l10n.itemName,
                  isDense: true,
                ),
                onChanged: (value) =>
                    onChanged(ExpenseFormItemUpdated(itemId: item.id, name: value)),
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: fair.negative,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: TextField(
                controller: controllers.quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                  isDense: true,
                ),
                onChanged: (value) {
                  final qty = int.tryParse(value);
                  if (qty != null && qty > 0) {
                    onChanged(
                      ExpenseFormItemUpdated(
                        itemId: item.id,
                        quantity: qty,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers.price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.itemPrice,
                  isDense: true,
                  prefixText: '${MoneyFormatter.symbolFor(state.currency)} ',
                ),
                onChanged: (value) {
                  final minor = MoneyFormatter.parse(
                    value,
                    currency: state.currency,
                  );
                  if (minor != null) {
                    onChanged(
                      ExpenseFormItemUpdated(
                        itemId: item.id,
                        unitPriceMinor: minor,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AmountText(
                minor: item.totalMinor,
                currency: state.currency,
                localeCode: locale,
                compact: true,
                style: context.texts.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            Pill(
              label: l10n.everyone,
              selected:
                  state.participantIds.isNotEmpty &&
                  item.memberIds.length == state.participantIds.length,
              onTap: () => onChanged(ExpenseFormItemEveryoneToggled(item.id)),
            ),
            for (final member in state.members)
              Pill(
                label: member.displayName,
                selected: item.memberIds.contains(member.userId),
                onTap: () => onChanged(
                  ExpenseFormItemMemberToggled(item.id, member.userId),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
