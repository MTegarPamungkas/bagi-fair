import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:flutter/material.dart';

/// Groups as ledger rows. Each row answers exactly one question: do I owe, am I
/// owed, or are we even?
class HomeGroupList extends StatelessWidget {
  const HomeGroupList({
    super.key,
    required this.groups,
    required this.onOpen,
    this.max = 4,
  });

  final List<GroupOverview> groups;
  final ValueChanged<GroupOverview> onOpen;
  final int max;

  @override
  Widget build(BuildContext context) {
    final visible = groups.take(max).toList(growable: false);
    final fair = context.fair;
    return FairCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            _GroupLedgerRow(
              overview: visible[i],
              onTap: () => onOpen(visible[i]),
            ),
            if (i != visible.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: fair.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupLedgerRow extends StatelessWidget {
  const _GroupLedgerRow({required this.overview, required this.onTap});

  final GroupOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final group = overview.group;
    final net =
        overview.summary.youAreOwedMinor - overview.summary.youOweMinor;
    final even = net == 0;
    final tone = even
        ? fair.accent
        : net > 0
        ? fair.positive
        : fair.negative;
    final label = even
        ? l10n.impas
        : net > 0
        ? l10n.youAreOwed
        : l10n.youOwe;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fair.surfaceMuted,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: fair.line),
              ),
              child: Text(group.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      l10n.groupTypeName(group.type),
                      l10n.membersCount(group.memberCount),
                      if (overview.expenseCount > 0)
                        l10n.expenseCount(overview.expenseCount),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 8.5,
                    letterSpacing: 0.3,
                    color: tone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (even)
                  Icon(Icons.check_circle_rounded, size: 18, color: tone)
                else
                  AmountText(
                    minor: net.abs(),
                    currency: group.currency,
                    localeCode: l10n.locale.languageCode,
                    compact: true,
                    color: tone,
                    style: context.texts.titleSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
