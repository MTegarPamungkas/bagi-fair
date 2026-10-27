import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/data/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showNudgeSheet(
  BuildContext context, {
  required String targetName,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NudgeSheet(targetName: targetName, message: message),
  );
}

class _NudgeSheet extends StatelessWidget {
  const _NudgeSheet({required this.targetName, required this.message});

  final String targetName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.nudgeSent,
              subtitle: targetName,
              icon: Icons.waving_hand_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.fair.accentSoft,
                borderRadius: AppRadius.allMd,
                border: Border.all(
                  color: context.fair.accent.withValues(alpha: 0.22),
                ),
              ),
              child: Text(message, style: context.texts.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        showFairSnack(context, l10n.copied);
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l10n.copy),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await getIt<ShareService>().shareToWhatsApp(message);
                    },
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: Text(l10n.shareWhatsApp),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.politeRemindersHint,
              textAlign: TextAlign.center,
              style: context.texts.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
