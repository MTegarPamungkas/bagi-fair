import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:flutter/material.dart';

/// Live preview of every share, plus the "Kenapa angkanya segini?" explanation.
class ExpensePreviewCard extends StatelessWidget {
  const ExpensePreviewCard({super.key, required this.state});

  final ExpenseFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    final fair = context.fair;
    return FairCard(
      tone: Color.alphaBlend(
        fair.accentSoft.withValues(alpha: 0.45),
        fair.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: l10n.breakdown,
                  subtitle: l10n.whyThisSubtitle,
                ),
              ),
              TextButton.icon(
                onPressed: () => showWhyDialog(context, state),
                icon: const Icon(Icons.help_outline_rounded, size: 17),
                label: Text(l10n.whyThis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.total.toUpperCase(),
                      style: context.texts.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    AmountText(
                      minor: state.baseAmountMinor,
                      currency: state.groupCurrency,
                      localeCode: locale,
                      style: context.texts.headlineMedium,
                    ),
                  ],
                ),
              ),
              if (state.isForeignCurrency)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.originalAmount, style: context.texts.labelSmall),
                    AmountText(
                      minor: state.amountMinor,
                      currency: state.currency,
                      localeCode: locale,
                      compact: true,
                      style: context.texts.titleMedium,
                    ),
                  ],
                ),
            ],
          ),
          const PerforatedDivider(height: 20),
          for (final share in state.shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AvatarCircle(name: state.nameFor(share.userId), size: 26),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      share.userId == state.payerId
                          ? '${state.nameFor(share.userId)} · ${l10n.paid}'
                          : state.nameFor(share.userId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall,
                    ),
                  ),
                  if (state.splitMode == SplitMode.percentage &&
                      share.weightBps > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        MoneyFormatter.percent(
                          share.weightBps / 10000,
                          localeCode: locale,
                        ),
                        style: context.texts.labelSmall?.copyWith(
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  AmountText(
                    minor: share.amountMinor,
                    currency: state.groupCurrency,
                    localeCode: locale,
                    style: context.texts.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Plain-language explanation of the arithmetic behind every share.
///
/// For itemized bills it also exposes the proportional tax/service/discount
/// lines, which is the part users (rightly) doubt.
void showWhyDialog(BuildContext context, ExpenseFormState state) {
  final l10n = context.l10n;
  final locale = l10n.locale.languageCode;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.whyThis),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.splitModeName(state.splitMode),
              style: dialogContext.texts.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              switch (state.splitMode) {
                SplitMode.equal => l10n.splitModeEqualHint,
                SplitMode.percentage => l10n.splitModePercentageHint,
                SplitMode.exact => l10n.splitModeExactHint,
                SplitMode.itemized => l10n.splitModeItemizedHint,
              },
              style: dialogContext.texts.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final share in state.shares) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.nameFor(share.userId),
                      style: dialogContext.texts.titleSmall,
                    ),
                  ),
                  Text(
                    MoneyFormatter.format(
                      share.amountMinor,
                      currency: state.groupCurrency,
                      localeCode: locale,
                    ),
                    style: AppTypography.money(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dialogContext.fair.ink,
                    ),
                  ),
                ],
              ),
              if (share.subtotalMinor > 0)
                _WhyLine(
                  label: l10n.subtotal,
                  value: MoneyFormatter.format(
                    share.subtotalMinor,
                    currency: state.groupCurrency,
                    localeCode: locale,
                  ),
                ),
              if (share.taxShareMinor > 0)
                _WhyLine(
                  label: l10n.tax,
                  value: MoneyFormatter.format(
                    share.taxShareMinor,
                    currency: state.groupCurrency,
                    localeCode: locale,
                  ),
                ),
              if (share.serviceShareMinor > 0)
                _WhyLine(
                  label: l10n.service,
                  value: MoneyFormatter.format(
                    share.serviceShareMinor,
                    currency: state.groupCurrency,
                    localeCode: locale,
                  ),
                ),
              if (share.discountShareMinor > 0)
                _WhyLine(
                  label: l10n.discount,
                  value:
                      '−${MoneyFormatter.format(share.discountShareMinor, currency: state.groupCurrency, localeCode: locale)}',
                ),
              if (share.adjustmentMinor != 0)
                _WhyLine(
                  label: l10n.t(
                    'Pembulatan',
                    'Rounding',
                  ),
                  value: MoneyFormatter.format(
                    share.adjustmentMinor,
                    currency: state.groupCurrency,
                    localeCode: locale,
                    signed: true,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
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

class _WhyLine extends StatelessWidget {
  const _WhyLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ),
          Text(
            value,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 10.5,
              fontFamily: AppTypography.mono,
            ),
          ),
        ],
      ),
    );
  }
}
