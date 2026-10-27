import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/group_menu.dart';
import 'package:flutter/material.dart';

/// Top of the group screen: one line of navigation, then a receipt header with
/// the member's own position. The group name appears once, not twice.
class GroupDetailHeader extends StatelessWidget {
  const GroupDetailHeader({
    super.key,
    required this.state,
    required this.onBack,
    required this.onInvite,
  });

  final GroupDetailState state;
  final VoidCallback onBack;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final group = state.group!;
    final fair = context.fair;
    final net = state.summary.youAreOwedMinor - state.summary.youOweMinor;
    final impas = net == 0;
    final tone = impas
        ? fair.inkMuted
        : net > 0
        ? fair.positive
        : fair.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.back,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.headlineSmall,
              ),
            ),
            if (MediaQuery.sizeOf(context).width < 430)
              IconButton(
                tooltip: l10n.inviteFriends,
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1_rounded),
              )
            else
              TextButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                label: Text(l10n.inviteFriends),
              ),            GroupMenu(group: group, state: state),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FairCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 5, color: tone),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Pill(
                          label: l10n.groupTypeName(group.type),
                          icon: GroupTypeIcon.iconFor(group.type),
                          dense: true,
                        ),
                        Pill(
                          label: l10n.membersCount(state.members.length),
                          icon: Icons.people_alt_outlined,
                          dense: true,
                        ),
                        if (state.expenses.isNotEmpty)
                          Pill(
                            label: l10n.expenseCount(state.expenses.length),
                            icon: Icons.receipt_long_outlined,
                            dense: true,
                          ),
                        if (group.archived)
                          Pill(
                            label: l10n.groupArchived,
                            dense: true,
                            tone: fair.tang,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.netPosition.toUpperCase(),
                                style: context.texts.labelSmall?.copyWith(
                                  fontSize: 9,
                                  letterSpacing: 1.6,
                                  color: fair.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AmountText(
                                minor: net,
                                currency: group.currency,
                                localeCode: l10n.locale.languageCode,
                                signed: !impas,
                                color: tone,
                                fit: true,
                                style: context.texts.displaySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                impas
                                    ? l10n.impasTitle
                                    : net > 0
                                    ? l10n.youAreOwed
                                    : l10n.youOwe,
                                style: context.texts.bodyMedium?.copyWith(
                                  color: tone,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (impas)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: StampBadge(
                              label: l10n.impas,
                              icon: Icons.done_all_rounded,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (group.description.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Text(
                    group.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall,
                  ),
                ),
              const PerforatedDivider(height: 22),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    AvatarStack(
                      names: state.members
                          .map((member) => member.displayName)
                          .toList(growable: false),
                      size: 28,
                      max: 5,
                    ),
                    const Spacer(),
                    Text(
                      '${l10n.totalGroupSpend}: ',
                      style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                    ),
                    Text(
                      MoneyFormatter.format(
                        state.summary.totalExpenseMinor,
                        currency: group.currency,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                      ),
                      style: AppTypography.money(
                        fontSize: 11,
                        color: fair.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
