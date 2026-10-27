import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final fair = sheetContext.fair;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SheetHeader(
                  title: sheetContext.l10n.currency,
                  icon: Icons.euro_rounded,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    AppSpacing.sm,
                    AppSpacing.lg,
                  ),
                  itemCount: MoneyFormatter.supportedCurrencies.length,
                  separatorBuilder: (_, _) => Divider(color: fair.line),
                  itemBuilder: (context, index) {
                    final code = MoneyFormatter.supportedCurrencies[index];
                    final active = code == selected;
                    return ListTile(
                      onTap: () => Navigator.of(sheetContext).pop(code),
                      leading: CircleAvatar(
                        backgroundColor: active
                            ? fair.accentSoft
                            : fair.surfaceMuted,
                        child: Text(
                          MoneyFormatter.symbolFor(code),
                          style: context.texts.labelMedium?.copyWith(
                            color: active ? fair.accent : fair.inkMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(code),
                      subtitle: Text(MoneyFormatter.names[code] ?? code),
                      trailing: active
                          ? Icon(Icons.check_rounded, color: fair.accent)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<Group?> showGroupPicker(
  BuildContext context, {
  required List<Group> groups,
  String? title,
}) {
  if (groups.isEmpty) return Future.value(null);
  return showModalBottomSheet<Group>(
    context: context,
    builder: (sheetContext) {
      final fair = sheetContext.fair;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: SheetHeader(
                title: title ?? sheetContext.l10n.groups,
                icon: Icons.groups_rounded,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.lg,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    onTap: () => Navigator.of(sheetContext).pop(group),
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fair.accentSoft,
                        borderRadius: AppRadius.allMd,
                      ),
                      child: Text(
                        group.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(group.name, maxLines: 1),
                    subtitle: Text(
                      '${sheetContext.l10n.groupTypeName(group.type)} · ${sheetContext.l10n.membersCount(group.memberCount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: fair.inkMuted,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<DateTime?> showFairDatePicker(
  BuildContext context, {
  required DateTime initial,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
}

Future<bool> showFairConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel ?? dialogContext.l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showFairSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String emojiForGroupType(GroupType type) => switch (type) {
  GroupType.trip => '🏝️',
  GroupType.kos => '🏠',
  GroupType.hangout => '☕',
  GroupType.other => '🎉',
};

const List<String> groupEmojiChoices = [
  '🏝️',
  '🏠',
  '☕',
  '🍕',
  '🎉',
  '🚗',
  '⛺',
  '🍜',
  '🎬',
  '⚽',
  '🎂',
  '✈️',
];
