import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

Future<void> showExpenseDetailSheet(
  BuildContext context, {
  required Expense expense,
  required String groupCurrency,
  required List<GroupMember> members,
  required String? currentUserId,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExpenseDetailSheet(
      expense: expense,
      groupCurrency: groupCurrency,
      members: members,
      currentUserId: currentUserId,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

class _ExpenseDetailSheet extends StatelessWidget {
  const _ExpenseDetailSheet({
    required this.expense,
    required this.groupCurrency,
    required this.members,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final String groupCurrency;
  final List<GroupMember> members;
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: expense.title,
                subtitle:
                    '${l10n.paidByLower} ${_name(context, expense.paidBy)} · ${AppDates.medium(expense.occurredAt, localeCode: locale)}',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AmountText(
                      minor: expense.amountMinor,
                      currency: expense.currency,
                      localeCode: locale,
                      style: context.texts.displaySmall,
                    ),
                  ),
                  if (expense.currency != groupCurrency)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.convertedTotal,
                          style: context.texts.labelSmall,
                        ),
                        AmountText(
                          minor: expense.amountBaseMinor,
                          currency: groupCurrency,
                          localeCode: locale,
                          style: context.texts.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  Pill(label: l10n.categoryName(expense.category), dense: true),
                  Pill(
                    label: l10n.splitModeName(expense.splitMode),
                    dense: true,
                  ),
                  Pill(
                    label: l10n.t(
                      '${expense.participantsCount} peserta',
                      '${expense.participantsCount} participants',
                    ),
                    dense: true,
                    icon: Icons.people_alt_outlined,
                  ),
                  if (expense.isPending)
                    Pill(
                      label: l10n.pendingSync,
                      dense: true,
                      tone: context.fair.warning,
                      icon: Icons.cloud_upload_outlined,
                    ),
                ],
              ),
              if (expense.receiptId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 15,
                      color: context.fair.info,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.receiptLinked,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.fair.info,
                      ),
                    ),
                  ],
                ),
              ],
              if (expense.note.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.fair.surfaceMuted,
                    borderRadius: AppRadius.allMd,
                  ),
                  child: Text(expense.note, style: context.texts.bodyMedium),
                ),
              ],
              if (expense.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: l10n.receiptItems),
                const SizedBox(height: AppSpacing.sm),
                for (final item in expense.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity > 1 ? '${item.quantity}× ' : ''}${item.name}',
                                style: context.texts.titleSmall,
                              ),
                              if (item.memberIds.isNotEmpty)
                                Text(
                                  item.memberIds
                                      .map((id) => _memberName(context, id))
                                      .join(', '),
                                  style: context.texts.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AmountText(
                          minor: item.totalMinor,
                          currency: expense.currency,
                          localeCode: locale,
                          style: context.texts.titleSmall,
                        ),
                      ],
                    ),
                  ),
                if (expense.taxMinor > 0 ||
                    expense.serviceMinor > 0 ||
                    expense.discountMinor > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InfoRow(
                    label: l10n.subtotal,
                    value: MoneyFormatter.format(
                      expense.itemsSubtotalMinor,
                      currency: expense.currency,
                      localeCode: locale,
                    ),
                  ),
                  if (expense.taxMinor > 0)
                    InfoRow(
                      label: l10n.tax,
                      value: MoneyFormatter.format(
                        expense.taxMinor,
                        currency: expense.currency,
                        localeCode: locale,
                      ),
                    ),
                  if (expense.serviceMinor > 0)
                    InfoRow(
                      label: l10n.service,
                      value: MoneyFormatter.format(
                        expense.serviceMinor,
                        currency: expense.currency,
                        localeCode: locale,
                      ),
                    ),
                  if (expense.discountMinor > 0)
                    InfoRow(
                      label: l10n.discount,
                      value:
                          '− ${MoneyFormatter.format(expense.discountMinor, currency: expense.currency, localeCode: locale)}',
                      valueColor: context.fair.positive,
                    ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: l10n.breakdown,
                subtitle: l10n.whyThisSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              FairCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    for (final share in expense.shares)
                      _ShareRow(
                        name: _name(context, share.userId),
                        isYou: share.userId == currentUserId,
                        share: share,
                        expense: expense,
                        groupCurrency: groupCurrency,
                        locale: locale,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete();
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: context.fair.negative,
                      ),
                      label: Text(
                        l10n.delete,
                        style: TextStyle(color: context.fair.negative),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(l10n.edit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _name(BuildContext context, String userId) {
    if (userId == currentUserId) return context.l10n.you;
    return _memberName(context, userId);
  }

  String _memberName(BuildContext context, String userId) {
    for (final member in members) {
      if (member.userId == userId) return member.displayName;
    }
    return context.l10n.member;
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.name,
    required this.isYou,
    required this.share,
    required this.expense,
    required this.groupCurrency,
    required this.locale,
  });

  final String name;
  final bool isYou;
  final ExpenseShare share;
  final Expense expense;
  final String groupCurrency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          AvatarCircle(name: name, size: 32, highlight: isYou),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.texts.titleSmall),
                if (expense.taxMinor > 0 ||
                    expense.serviceMinor > 0 ||
                    expense.discountMinor > 0)
                  Text(
                    [
                      if (share.taxShareMinor > 0)
                        '${l10n.tax} ${MoneyFormatter.format(share.taxShareMinor, currency: groupCurrency, localeCode: locale)}',
                      if (share.serviceShareMinor > 0)
                        '${l10n.service} ${MoneyFormatter.format(share.serviceShareMinor, currency: groupCurrency, localeCode: locale)}',
                      if (share.discountShareMinor > 0)
                        '${l10n.discount} −${MoneyFormatter.format(share.discountShareMinor, currency: groupCurrency, localeCode: locale)}',
                    ].join(' · '),
                    style: context.texts.bodySmall?.copyWith(fontSize: 10),
                  ),
                if (share.weightBps > 0 &&
                    expense.splitMode == SplitMode.percentage)
                  Text(
                    '${MoneyFormatter.percent(share.weightBps / 10000, localeCode: locale)} ${l10n.shareOfTotal}',
                    style: context.texts.bodySmall?.copyWith(fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(
            minor: share.amountMinor,
            currency: groupCurrency,
            localeCode: locale,
            style: context.texts.titleSmall,
          ),
          IconButton(
            tooltip: l10n.whyThis,
            onPressed: () => _explain(context),
            icon: const Icon(Icons.help_outline_rounded, size: 17),
          ),
        ],
      ),
    );
  }

  void _explain(BuildContext context) {
    final l10n = context.l10n;
    final lines = <String>[
      l10n.t(
        'Nominal asli dibagi dengan aturan ${l10n.splitModeName(expense.splitMode)}.',
        'The original amount is split using the ${l10n.splitModeName(expense.splitMode)} rule.',
      ),
      if (share.subtotalMinor > 0)
        l10n.t(
          'Subtotal item: ${MoneyFormatter.format(share.subtotalMinor, currency: groupCurrency, localeCode: locale)}',
          'Item subtotal: ${MoneyFormatter.format(share.subtotalMinor, currency: groupCurrency, localeCode: locale)}',
        ),
      if (share.taxShareMinor != 0)
        l10n.t(
          'Pajak proporsional: ${MoneyFormatter.format(share.taxShareMinor, currency: groupCurrency, localeCode: locale)}',
          'Proportional tax: ${MoneyFormatter.format(share.taxShareMinor, currency: groupCurrency, localeCode: locale)}',
        ),
      if (share.serviceShareMinor != 0)
        l10n.t(
          'Service proporsional: ${MoneyFormatter.format(share.serviceShareMinor, currency: groupCurrency, localeCode: locale)}',
          'Proportional service: ${MoneyFormatter.format(share.serviceShareMinor, currency: groupCurrency, localeCode: locale)}',
        ),
      if (share.discountShareMinor != 0)
        l10n.t(
          'Diskon proporsional: −${MoneyFormatter.format(share.discountShareMinor, currency: groupCurrency, localeCode: locale)}',
          'Proportional discount: −${MoneyFormatter.format(share.discountShareMinor, currency: groupCurrency, localeCode: locale)}',
        ),
      if (share.adjustmentMinor != 0)
        l10n.t(
          'Penyesuaian pembulatan: ${MoneyFormatter.format(share.adjustmentMinor, currency: groupCurrency, localeCode: locale, signed: true)}',
          'Rounding adjustment: ${MoneyFormatter.format(share.adjustmentMinor, currency: groupCurrency, localeCode: locale, signed: true)}',
        ),
      l10n.t(
        'Total bagian: ${MoneyFormatter.format(share.amountMinor, currency: groupCurrency, localeCode: locale)}',
        'Final share: ${MoneyFormatter.format(share.amountMinor, currency: groupCurrency, localeCode: locale)}',
      ),
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.whyThis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: dialogContext.texts.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: dialogContext.texts.bodyMedium),
                    Expanded(
                      child: Text(line, style: dialogContext.texts.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
