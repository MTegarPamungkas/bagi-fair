import 'dart:typed_data';

import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:flutter/material.dart';

/// Step 1.5: the photo is already picked and the Edge Function is doing the
/// OCR. Without this stage the screen looked frozen — the picker button just
/// stopped spinning and nothing else changed while Gemini worked.
class ScanAnalyzingStage extends StatelessWidget {
  const ScanAnalyzingStage({super.key, required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final preview = imageBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FairCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              if (preview != null && preview.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.all(AppRadius.md),
                  child: Image.memory(
                    preview,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: fair.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.scanningReceipt,
                textAlign: TextAlign.center,
                style: context.texts.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.scanningReceiptBody,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FairCard(
          tone: fair.blueSoft,
          borderColor: fair.blue.withValues(alpha: 0.25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 17, color: fair.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.aiPrivacy, style: context.texts.bodySmall),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
