import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expenses/presentation/widgets/expense_tile.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/expense_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupExpensesTab extends StatelessWidget {
  const GroupExpensesTab({super.key, required this.state});

  final GroupDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.expenses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: l10n.noExpenses,
            body: l10n.noExpensesBody,
            action: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/groups/${state.group!.id}/expenses/new'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addExpense),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/groups/${state.group!.id}/scan'),
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: Text(l10n.scanReceipt),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final sorted = [...state.expenses]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final fair = context.fair;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        AppSpacing.sm,
        context.pagePadding,
        120,
      ),
      children: [
        FairCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Column(
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                _tile(context, sorted[i]),
                if (i != sorted.length - 1)
                  Divider(
                    height: 1,
                    indent: 4,
                    endIndent: 4,
                    color: fair.line,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, Expense expense) {
    final share = state.currentUserId == null
        ? null
        : expense.shareFor(state.currentUserId!);
    return ExpenseTile(
      expense: expense,
      currency: state.currency,
      payerName: state.nameFor(expense.paidBy),
      yourShareMinor: share?.amountMinor,
      flat: true,
      onTap: () => _openDetail(context, expense),
    );
  }

  void _openDetail(BuildContext context, Expense expense) {
    showExpenseDetailSheet(
      context,
      expense: expense,
      groupCurrency: state.currency,
      members: state.members,
      currentUserId: state.currentUserId,
      onEdit: () {
        context.push('/groups/${state.group!.id}/expenses/${expense.id}');
      },
      onDelete: () async {
        final l10n = context.l10n;
        final confirmed = await showFairConfirm(
          context,
          title: l10n.deleteExpenseTitle,
          body: l10n.deleteExpenseBody,
          confirmLabel: l10n.delete,
        );
        if (confirmed && context.mounted) {
          context.read<GroupDetailBloc>().add(
            GroupDetailDeleteExpenseRequested(expense),
          );
        }
      },
    );
  }
}
