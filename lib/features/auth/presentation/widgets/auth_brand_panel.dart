import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:flutter/material.dart';

/// The left-hand story on wide screens, and the compact header on phones.
///
/// Instead of a tinted marketing card, it shows an actual mini receipt with a
/// proportional split, because that is the promise: every number is visible.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FairLogo(size: 52, showWordmark: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.welcomeTitle,
            style: context.texts.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(l10n.welcomeBody, style: context.texts.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FairLogo(size: 54, showWordmark: true),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l10n.welcomeTitle,
          style: context.texts.displaySmall?.copyWith(height: 1.02),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(l10n.welcomeBody, style: context.texts.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const _SplitExampleReceipt(),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 16,
              color: fair.inkMuted,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                l10n.authSecureNote,
                style: context.texts.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SplitExampleReceipt extends StatelessWidget {
  const _SplitExampleReceipt();

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return FairCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'MAKAN MALAM JIMBARAN',
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: fair.inkMuted,
                ),
              ),
              const Spacer(),
              Text(
                '16 OKT',
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: fair.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp 945.000', style: context.texts.displaySmall),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.l10n.perPerson,
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const PerforatedDivider(height: 18),
          _ExampleRow(name: 'Budi', amount: '322.500', tone: fair.accent),
          _ExampleRow(name: 'Sinta', amount: '322.500', tone: fair.tang),
          _ExampleRow(name: 'Andi', amount: '300.000', tone: fair.blue),
          const PerforatedDivider(height: 18),
          Row(
            children: [
              Icon(Icons.calculate_outlined, size: 13, color: fair.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  context.l10n.t(
                    'Pajak & service dibagi sesuai subtotal item.',
                    'Tax & service split by item subtotal.',
                  ),
                  style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.name,
    required this.amount,
    required this.tone,
  });

  final String name;
  final String amount;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: context.texts.bodyMedium)),
          Text(
            'Rp $amount',
            style: AppTypography.money(
              fontSize: 12.5,
              color: fair.ink,
            ),
          ),
        ],
      ),
    );
  }
}
