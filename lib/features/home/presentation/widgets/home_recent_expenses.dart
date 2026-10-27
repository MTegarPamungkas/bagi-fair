import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:bagi_fair/features/expenses/presentation/widgets/expense_tile.dart';
import 'package:flutter/material.dart';

class HomeRecentExpenses extends StatelessWidget {
  const HomeRecentExpenses({
    super.key,
    required this.expenses,
    required this.groups,
    required this.user,
    required this.onOpenGroup,
  });

  final List<Expense> expenses;
  final List<GroupOverview> groups;
  final AppUser? user;
  final ValueChanged<String> onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final visible = expenses.take(4).toList(growable: false);
    return FairCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            Builder(
              builder: (context) {
                final expense = visible[i];
                final group = _groupFor(expense.groupId);
                final payer = group?.nameFor(expense.paidBy) ?? context.l10n.you;
                final share = user == null
                    ? null
                    : expense.shareFor(user!.id);
                return ExpenseTile(
                  expense: expense,
                  currency: group?.group.currency ?? expense.currency,
                  payerName: payer,
                  groupName: group?.group.name,
                  yourShareMinor: share?.amountMinor,
                  showGroup: true,
                  flat: true,
                  onTap: () => onOpenGroup(expense.groupId),
                );
              },
            ),
            if (i != visible.length - 1)
              Divider(
                height: 1,
                indent: 4,
                endIndent: 4,
                color: fair.line,
              ),
          ],
        ],
      ),
    );
  }

  GroupOverview? _groupFor(String groupId) {
    for (final group in groups) {
      if (group.group.id == groupId) return group;
    }
    return null;
  }
}

class HomeNotificationPreview extends StatelessWidget {
  const HomeNotificationPreview({
    super.key,
    required this.notifications,
    required this.onOpen,
  });

  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final locale = context.l10n.locale.languageCode;
    return FairCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < notifications.length; i++) ...[
            ListTile(
              onTap: () => onOpen(notifications[i]),
              leading: _NotificationGlyph(kind: notifications[i].kind),
              title: Text(
                notifications[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall?.copyWith(
                  fontWeight: notifications[i].isUnread
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                notifications[i].body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                AppDates.relative(
                  notifications[i].createdAt,
                  localeCode: locale,
                ),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 0,
                  fontSize: 9,
                ),
              ),
            ),
            if (i != notifications.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: fair.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationGlyph extends StatelessWidget {
  const _NotificationGlyph({required this.kind});

  final AppNotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final (icon, tone) = switch (kind) {
      AppNotificationKind.nudge => (Icons.waving_hand_outlined, fair.tang),
      AppNotificationKind.expenseAdded => (
        Icons.receipt_long_outlined,
        fair.accent,
      ),
      AppNotificationKind.settlementAdded => (
        Icons.check_circle_outline,
        fair.positive,
      ),
      AppNotificationKind.memberJoined => (
        Icons.person_add_alt_1_outlined,
        fair.blue,
      ),
      AppNotificationKind.reminder => (
        Icons.notifications_none_rounded,
        fair.info,
      ),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, size: 18, color: tone),
    );
  }
}
