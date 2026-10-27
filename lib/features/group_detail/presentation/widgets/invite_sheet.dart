import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/data/services/share_service.dart';
import 'package:bagi_fair/domain/entities/group_invite.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showInviteSheet(
  BuildContext context, {
  required String groupId,
  required String groupName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _InviteSheet(groupId: groupId, groupName: groupName),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  GroupInvite? _invite;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invite = await getIt<CreateGroupInvite>()(widget.groupId);
      if (!mounted) return;
      setState(() {
        _invite = invite;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.inviteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final link = _invite == null ? null : AppConfig.inviteLink(_invite!.code);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.inviteSheetTitle,
              subtitle: widget.groupName,
              icon: Icons.person_add_alt_1_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.inviteSheetBody, style: context.texts.bodySmall),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const LoadingState(padding: AppSpacing.lg)
            else if (_error != null)
              Column(
                children: [
                  Text(_error!, style: context.texts.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
                  ),
                ],
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.fair.accentSoft,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(
                    color: context.fair.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.inviteCode.toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _invite!.code,
                      style: context.texts.displaySmall?.copyWith(
                        color: context.fair.accent,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                link!,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          showFairSnack(context, l10n.linkCopied);
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.copyLink),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final text =
                            '${l10n.inviteSheetTitle} · ${widget.groupName}\n$link';
                        await getIt<ShareService>().shareToWhatsApp(text);
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(l10n.shareWhatsApp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final text =
                            '${l10n.inviteSheetTitle} · ${widget.groupName}\n$link';
                        await getIt<ShareService>().shareText(
                          text,
                          subject: widget.groupName,
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 17),
                      label: Text(l10n.shareInvite),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.autorenew_rounded, size: 17),
                      label: Text(l10n.refreshLink),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
