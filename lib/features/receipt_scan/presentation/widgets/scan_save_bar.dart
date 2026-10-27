import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/bloc/receipt_scan_bloc.dart';
import 'package:flutter/material.dart';

class ScanSaveBar extends StatelessWidget {
  const ScanSaveBar({super.key, required this.state, required this.onSave});

  final ReceiptScanState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.pagePadding,
          AppSpacing.sm,
          context.pagePadding,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: fair.surface,
          border: Border(top: BorderSide(color: fair.line)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.total,
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      AmountText(
                        minor: state.computedTotal,
                        currency: state.currency,
                        localeCode: l10n.locale.languageCode,
                        style: context.texts.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: state.saving ? null : onSave,
                  icon: state.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(state.saving ? l10n.loading : l10n.saveReceipt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
