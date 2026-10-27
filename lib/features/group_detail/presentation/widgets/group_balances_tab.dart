import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/settle_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupBalancesTab extends StatelessWidget {
  const GroupBalancesTab({super.key, required this.state});

  final GroupDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    final currency = state.currency;
    final fair = context.fair;
    final balances = [...state.summary.balances]
      ..sort((a, b) => b.netMinor.compareTo(a.netMinor));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        AppSpacing.sm,
        context.pagePadding,
        120,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: l10n.total,
                icon: Icons.receipt_long_outlined,
                value: AmountText(
                  minor: state.summary.totalExpenseMinor,
                  currency: currency,
                  localeCode: locale,
                  compact: true,
                  style: context.texts.titleMedium,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricTile(
                label: l10n.yourShare,
                icon: Icons.pie_chart_outline_rounded,
                tone: fair.blue,
                value: AmountText(
                  minor: state.summary.yourShareMinor,
                  currency: currency,
                  localeCode: locale,
                  compact: true,
                  style: context.texts.titleMedium,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricTile(
                label: l10n.netPosition,
                icon: Icons.balance_rounded,
                tone: state.summary.isImpas
                    ? fair.inkMuted
                    : state.summary.youAreOwedMinor >=
                          state.summary.youOweMinor
                    ? fair.positive
                    : fair.negative,
                value: AmountText(
                  minor:
                      (state.summary.youAreOwedMinor -
                              state.summary.youOweMinor)
                          .abs(),
                  currency: currency,
                  localeCode: locale,
                  compact: true,
                  style: context.texts.titleMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.whoOwesWhom,
          subtitle: l10n.settleSubtitle,
          action: state.summary.transfers.isEmpty
              ? null
              : TextButton(
                  onPressed: () => _settleAll(context),
                  child: Text(l10n.settleAllTransfers),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.summary.isImpas)
          FairCard(
            child: Row(
              children: [
                StampBadge(
                  label: l10n.impas,
                  icon: Icons.done_all_rounded,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.impasTitle, style: context.texts.titleMedium),
                      const SizedBox(height: 2),
                      Text(l10n.impasBody, style: context.texts.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          FairCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < state.summary.transfers.length; i++) ...[
                  _TransferRow(
                    transfer: state.summary.transfers[i],
                    state: state,
                    onSettle: () =>
                        _settle(context, state.summary.transfers[i]),
                  ),
                  if (i != state.summary.transfers.length - 1)
                    Divider(
                      height: 1,
                      indent: AppSpacing.sm,
                      endIndent: AppSpacing.sm,
                      color: fair.line,
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.members,
          subtitle: l10n.t(
            'Posisi tiap orang di grup ini.',
            'Each person’s position in this group.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FairCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < balances.length; i++) ...[
                _BalanceRow(
                  balance: balances[i],
                  state: state,
                  onNudge: balances[i].netMinor < 0 &&
                          balances[i].userId != state.currentUserId
                      ? () => context.read<GroupDetailBloc>().add(
                          GroupDetailNudgeRequested(balances[i].userId),
                        )
                      : null,
                ),
                if (i != balances.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: fair.line,
                  ),
              ],
            ],
          ),
        ),
        if (state.settlements.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.settlementHistory),
          const SizedBox(height: AppSpacing.sm),
          FairCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final settlement in ([...state.settlements]
                  ..sort((a, b) => b.settledAt.compareTo(a.settledAt))))
                  ListTile(
                    leading: Icon(
                      Icons.check_circle_outline_rounded,
                      color: fair.positive,
                    ),
                    title: Text(
                      '${state.nameFor(settlement.fromUserId)} ${l10n.settlementFromTo} ${state.nameFor(settlement.toUserId)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        AppDates.medium(
                          settlement.settledAt,
                          localeCode: locale,
                        ),
                        if (settlement.note.trim().isNotEmpty) settlement.note,
                      ].join(' · '),
                    ),
                    trailing: AmountText(
                      minor: settlement.amountMinor,
                      currency: currency,
                      localeCode: locale,
                      style: context.texts.titleSmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _settle(
    BuildContext context,
    TransferSuggestion transfer,
  ) async {
    final draft = await showSettleSheet(
      context,
      currency: state.currency,
      members: state.members,
      currentUserId: state.currentUserId ?? '',
      fromUserId: transfer.fromUserId,
      toUserId: transfer.toUserId,
      amountMinor: transfer.amountMinor,
    );
    if (draft != null && context.mounted) {
      context.read<GroupDetailBloc>().add(
        GroupDetailSettlementSubmitted(
          fromUserId: draft.fromUserId,
          toUserId: draft.toUserId,
          amountMinor: draft.amountMinor,
          note: draft.note,
        ),
      );
    }
  }

  Future<void> _settleAll(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showFairConfirm(
      context,
      title: l10n.settleAllTransfers,
      body: l10n.settleAllBody,
      confirmLabel: l10n.markSettled,
    );
    if (!confirmed || !context.mounted) return;
    final bloc = context.read<GroupDetailBloc>();
    for (final transfer in state.summary.transfers) {
      bloc.add(
        GroupDetailSettlementSubmitted(
          fromUserId: transfer.fromUserId,
          toUserId: transfer.toUserId,
          amountMinor: transfer.amountMinor,
        ),
      );
    }
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.state,
    required this.onSettle,
  });

  final TransferSuggestion transfer;
  final GroupDetailState state;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final locale = l10n.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AvatarCircle(name: state.nameFor(transfer.fromUserId), size: 34),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.nameFor(transfer.fromUserId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: fair.inkMuted,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        state.nameFor(transfer.toUserId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          color: fair.positive,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AmountText(
                  minor: transfer.amountMinor,
                  currency: state.currency,
                  localeCode: locale,
                  style: context.texts.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilledButton.tonal(
            onPressed: onSettle,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.settleUp),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.state, this.onNudge});

  final MemberBalance balance;
  final GroupDetailState state;
  final VoidCallback? onNudge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    final fair = context.fair;
    final member = state.memberFor(balance.userId);
    final tone = balance.netMinor > 0
        ? fair.positive
        : balance.netMinor < 0
        ? fair.negative
        : fair.inkMuted;
    return ListTile(
      leading: AvatarCircle(
        name: member?.displayName ?? '?',
        imageUrl: member?.avatarUrl,
        size: 36,
        highlight: balance.userId == state.currentUserId,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              state.nameFor(balance.userId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member?.role == GroupRole.owner) ...[
            const SizedBox(width: 5),
            Pill(label: l10n.owner, dense: true),
          ],
        ],
      ),
      subtitle: Text(
        '${l10n.paid} ${MoneyFormatter.format(balance.paidMinor, currency: state.currency, localeCode: locale, compact: true)} · ${l10n.owes} ${MoneyFormatter.format(balance.owedMinor, currency: state.currency, localeCode: locale, compact: true)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                balance.netMinor == 0
                    ? l10n.impas
                    : balance.netMinor > 0
                    ? l10n.isOwed
                    : l10n.owes,
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.3,
                  color: tone,
                ),
              ),
              AmountText(
                minor: balance.netMinor.abs(),
                currency: state.currency,
                localeCode: locale,
                compact: true,
                color: tone,
                style: context.texts.titleSmall,
              ),
            ],
          ),
          if (onNudge != null)
            IconButton(
              tooltip: l10n.nudgeFriend,
              onPressed: onNudge,
              icon: const Icon(Icons.waving_hand_outlined, size: 19),
            ),
        ],
      ),
    );
  }
}
