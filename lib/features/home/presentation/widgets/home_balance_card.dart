import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:flutter/material.dart';

/// The first thing a user should see: their own net position, printed like the
/// top of a receipt. The three supporting numbers live on the same sheet so the
/// eye does not have to jump between cards.
class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({super.key, required this.overview});

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final locale = l10n.locale.languageCode;
    final currency = overview.groups.isEmpty
        ? 'IDR'
        : overview.groups.first.group.currency;
    final impas = overview.isImpas;
    final net = overview.netMinor;
    final tone = impas
        ? fair.inkMuted
        : net > 0
        ? fair.positive
        : fair.negative;
    final label = impas
        ? l10n.impasTitle
        : net > 0
        ? l10n.youAreOwed
        : l10n.youOwe;

    return FairCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 5, color: tone),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.netPosition.toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        color: fair.inkMuted,
                      ),
                    ),
                    const Spacer(),
                    if (impas)
                      StampBadge(label: l10n.impas, icon: Icons.done_all_rounded)
                    else
                      Text(
                        l10n.t(
                          '${overview.groups.length} grup aktif',
                          '${overview.groups.length} active groups',
                        ),
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.2,
                          color: fair.inkMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AmountText(
                  minor: net,
                  currency: currency,
                  localeCode: locale,
                  signed: !impas,
                  color: tone,
                  fit: true,
                  style: context.texts.displayMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: context.texts.bodyMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const PerforatedDivider(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.total,
                    minor: overview.totalSpendMinor,
                    currency: currency,
                    localeCode: locale,
                  ),
                ),
                _StatDivider(color: fair.line),
                Expanded(
                  child: _Stat(
                    label: l10n.youOwe,
                    minor: overview.youOweMinor,
                    currency: currency,
                    localeCode: locale,
                    tone: overview.youOweMinor > 0 ? fair.negative : null,
                  ),
                ),
                _StatDivider(color: fair.line),
                Expanded(
                  child: _Stat(
                    label: l10n.youAreOwed,
                    minor: overview.youAreOwedMinor,
                    currency: currency,
                    localeCode: locale,
                    tone: overview.youAreOwedMinor > 0 ? fair.positive : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.minor,
    required this.currency,
    required this.localeCode,
    this.tone,
  });

  final String label;
  final int minor;
  final String currency;
  final String localeCode;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          style: context.texts.labelSmall?.copyWith(
            fontSize: 8.5,
            letterSpacing: 0.7,
            height: 1.25,
            color: fair.inkMuted,
          ),
        ),
        const SizedBox(height: 5),
        AmountText(
          minor: minor,
          currency: currency,
          localeCode: localeCode,
          compact: true,
          color: tone ?? fair.ink,
          style: context.texts.titleSmall,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: color,
    );
  }
}
