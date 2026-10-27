import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:flutter/material.dart';

/// Step 1: explain the trade-off, offer camera/gallery/sample, and always keep
/// a manual escape hatch.
class ScanUploadStage extends StatelessWidget {
  const ScanUploadStage({
    super.key,
    required this.groupName,
    required this.picking,
    required this.onCamera,
    required this.onGallery,
    required this.onSample,
    required this.onManual,
  });

  final String groupName;
  final bool picking;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSample;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FairCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: fair.accentSoft,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: fair.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  size: 38,
                  color: fair.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.scanTitle,
                textAlign: TextAlign.center,
                style: context.texts.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                groupName.isEmpty
                    ? l10n.scanSubtitle
                    : l10n.t(
                        'Foto struk $groupName, biar kami yang hitung.',
                        'Snap the $groupName receipt and we will do the math.',
                      ),
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _PickButton(
                      icon: Icons.photo_camera_rounded,
                      label: l10n.takePhoto,
                      filled: true,
                      loading: picking,
                      onTap: onCamera,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickButton(
                      icon: Icons.photo_library_outlined,
                      label: l10n.choosePhoto,
                      onTap: onGallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: onSample,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text(l10n.scanDemo),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FairCard(
          tone: fair.blueSoft,
          borderColor: fair.blue.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 17, color: fair.blue),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      l10n.aiPowered,
                      style: context.texts.titleSmall?.copyWith(
                        color: fair.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.aiPrivacy, style: context.texts.bodySmall),
              const SizedBox(height: 4),
              Text(
                l10n.t(
                  'Batas ${AppConfig.aiRateLimitPerHour} scan per jam per akun.',
                  'Limited to ${AppConfig.aiRateLimitPerHour} scans per hour per account.',
                ),
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: fair.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FairCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('Tips foto struk', 'Photo tips'),
                style: context.texts.titleSmall,
              ),
              const SizedBox(height: 8),
              _TipRow(
                icon: Icons.light_mode_outlined,
                text: l10n.t(
                  'Cahaya cukup, hindari bayangan.',
                  'Good lighting, avoid shadows.',
                ),
              ),
              _TipRow(
                icon: Icons.crop_free_rounded,
                text: l10n.t(
                  'Pastikan seluruh struk masuk frame.',
                  'Keep the whole receipt in frame.',
                ),
              ),
              _TipRow(
                icon: Icons.straighten_rounded,
                text: l10n.t(
                  'Foto tegak lurus, jangan miring.',
                  'Hold the camera straight.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: onManual,
            icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
            label: Text(l10n.manualEntry),
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: context.fair.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.texts.bodySmall)),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.texts.titleSmall,
        ),
      ],
    );
    final padding = const EdgeInsets.symmetric(vertical: AppSpacing.lg);
    return filled
        ? FilledButton(onPressed: loading ? null : onTap, child: child)
        : OutlinedButton(
            onPressed: loading ? null : onTap,
            style: OutlinedButton.styleFrom(padding: padding),
            child: child,
          );
  }
}
