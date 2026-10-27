import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.netMinor,
    this.expenseCount,
  });

  final Group group;
  final VoidCallback onTap;
  final int? netMinor;
  final int? expenseCount;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final l10n = context.l10n;
    final net = netMinor;
    final tone = net == null || net == 0
        ? fair.inkMuted
        : net > 0
        ? fair.positive
        : fair.negative;
    final netLabel = net == null
        ? ''
        : net == 0
        ? l10n.impas
        : net > 0
        ? l10n.youAreOwed
        : l10n.youOwe;

    final netBlock = net == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                netLabel,
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.4,
                  color: tone,
                ),
              ),
              const SizedBox(height: 2),
              AmountText(
                minor: net.abs(),
                currency: group.currency,
                localeCode: l10n.locale.languageCode,
                compact: true,
                color: tone,
                style: context.texts.titleSmall,
              ),
            ],
          );

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fair.accentSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: fair.accent.withValues(alpha: 0.18)),
          ),
          child: Text(group.emoji, style: const TextStyle(fontSize: 23)),
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
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Pill(label: l10n.groupTypeName(group.type), dense: true),
                  Pill(
                    label: l10n.membersCount(group.memberCount),
                    dense: true,
                    icon: Icons.people_alt_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return FairCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // On narrow phones a large balance would squeeze the group name
              // and its chips, so give the balance its own row instead.
              if (netBlock == null) return identity;
              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: netBlock,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: AppSpacing.xs),
                  netBlock,
                ],
              );
            },
          ),
          if (group.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall,
            ),
          ],
          if (expenseCount != null && expenseCount! > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 13,
                  color: fair.inkMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.expenseCount(expenseCount!),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 0,
                    fontSize: 9.5,
                  ),
                ),
                const Spacer(),
                if (context.isExpanded)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: fair.inkMuted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
