import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:flutter/material.dart';

/// Small honest indicator of what the local cache is doing.
class SyncChip extends StatelessWidget {
  const SyncChip({
    super.key,
    required this.status,
    this.onTap,
    this.expanded = false,
  });

  final SyncStatus status;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final (label, icon, tone) = switch (status.phase) {
      SyncPhase.demo => (l10n.localMode, Icons.science_outlined, fair.blue),
      SyncPhase.syncing => (l10n.syncing, Icons.sync_rounded, fair.info),
      SyncPhase.offline => (
        l10n.offline,
        Icons.cloud_off_rounded,
        fair.inkMuted,
      ),
      SyncPhase.error => (
        l10n.somethingWrong,
        Icons.error_outline_rounded,
        fair.negative,
      ),
      SyncPhase.idle =>
        status.pendingCount > 0
            ? (
                '${status.pendingCount}',
                Icons.cloud_upload_outlined,
                fair.warning,
              )
            : (l10n.synced, Icons.cloud_done_outlined, fair.positive),
    };

    return Tooltip(
      message: l10n.syncNow,
      child: InkWell(
        borderRadius: AppRadius.allPill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.1),
            borderRadius: AppRadius.allPill,
            border: Border.all(color: tone.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.phase == SyncPhase.syncing)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: tone,
                  ),
                )
              else
                Icon(icon, size: 12, color: tone),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  color: tone,
                  fontFamily: AppTypography.mono,
                  fontSize: 8.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
