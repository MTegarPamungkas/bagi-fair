import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The one global "add" action. It asks *what* is being added before asking
/// which group, which is fewer taps than hunting for a group first.
Future<void> showQuickAddSheet(BuildContext context) async {
  final l10n = context.l10n;
  final fair = context.fair;
  final groups = await _loadGroups();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.add, style: sheetContext.texts.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.t(
                'Mulai dari mana? Semua akan tercatat adil.',
                'Where do we start? Everything stays fair.',
              ),
              style: sheetContext.texts.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _QuickActionRow(
              icon: Icons.receipt_long_rounded,
              tone: fair.accent,
              title: l10n.addExpense,
              subtitle: l10n.t(
                'Isi nominal, pilih siapa yang ikut.',
                'Enter an amount, pick who joined.',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _withGroup(
                  context,
                  groups,
                  (group) => context.push('/groups/${group.id}/expenses/new'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _QuickActionRow(
              icon: Icons.document_scanner_outlined,
              tone: fair.blue,
              title: l10n.scanReceipt,
              subtitle: l10n.t(
                'Foto struk, AI baca, kamu koreksi.',
                'Photograph a receipt, review the lines.',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _withGroup(
                  context,
                  groups,
                  (group) => context.push('/groups/${group.id}/scan'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _QuickActionRow(
              icon: Icons.group_add_outlined,
              tone: fair.tang,
              title: l10n.newGroup,
              subtitle: l10n.t(
                'Trip, kos, atau nongkrong baru.',
                'A new trip, rent, or hangout.',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/groups/new');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<List<Group>> _loadGroups() async {
  try {
    final groups = await getIt<WatchGroups>()().first.timeout(
      const Duration(seconds: 2),
    );
    return groups;
  } catch (_) {
    return const [];
  }
}

Future<void> _withGroup(
  BuildContext context,
  List<Group> groups,
  void Function(Group group) action,
) async {
  if (groups.isEmpty) {
    await context.push('/groups/new');
    return;
  }
  if (groups.length == 1) {
    action(groups.first);
    return;
  }
  final group = await showGroupPicker(context, groups: groups);
  if (group != null && context.mounted) action(group);
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: fair.surface,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: fair.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: AppRadius.allMd,
              ),
              child: Icon(icon, size: 20, color: tone),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.texts.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: fair.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
