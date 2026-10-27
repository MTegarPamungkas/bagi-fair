import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    return BlocProvider(
      create: (_) {
        final bloc = getIt<NotificationsBloc>();
        if (user != null) bloc.add(NotificationsStarted(user.id));
        return bloc;
      },
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final items = _unreadOnly
            ? state.notifications.where((item) => item.isUnread).toList()
            : state.notifications;
        final grouped = _group(items);
        return FairBackground(
          child: RefreshIndicator(
            onRefresh: () async => context.read<NotificationsBloc>().add(
              const NotificationsRefreshRequested(),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                18,
                context.pagePadding,
                120,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PageHeader(
                          eyebrow: l10n.notificationsTitle,
                          title: state.unreadCount == 0
                              ? l10n.allCaughtUp
                              : l10n.t(
                                  '${state.unreadCount} kabar baru',
                                  '${state.unreadCount} new updates',
                                ),
                          subtitle: l10n.notificationsSubtitle,
                          actions: [
                            if (state.unreadCount > 0 && user != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.read<NotificationsBloc>().add(
                                      NotificationsAllReadRequested(user.id),
                                    ),
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                  size: 17,
                                ),
                                label: Text(l10n.markAllRead),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Pill(
                              label: l10n.all,
                              icon: Icons.inbox_rounded,
                              selected: !_unreadOnly,
                              onTap: () => setState(() => _unreadOnly = false),
                            ),
                            Pill(
                              label: l10n.t('Belum dibaca', 'Unread'),
                              icon: Icons.mark_email_unread_outlined,
                              selected: _unreadOnly,
                              onTap: () => setState(() => _unreadOnly = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (state.loading && state.notifications.isEmpty)
                          const LoadingState()
                        else if (state.error != null &&
                            state.notifications.isEmpty)
                          ErrorState(
                            message: l10n.loadFailed,
                            onRetry: () => context
                                .read<NotificationsBloc>()
                                .add(const NotificationsRefreshRequested()),
                          )
                        else if (items.isEmpty)
                          EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: _unreadOnly
                                ? l10n.t(
                                    'Tidak ada yang belum dibaca.',
                                    'Nothing left unread.',
                                  )
                                : l10n.noNotifications,
                            body: l10n.noNotificationsBody,
                          )
                        else
                          for (final entry in grouped.entries) ...[
                            _DayLabel(label: entry.key),
                            const SizedBox(height: AppSpacing.xs),
                            for (final notification in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: _NotificationTile(
                                  notification: notification,
                                  onTap: () {
                                    if (notification.isUnread) {
                                      context.read<NotificationsBloc>().add(
                                        NotificationReadRequested(notification),
                                      );
                                    }
                                    if (notification.groupId.isNotEmpty) {
                                      context.push(
                                        '/groups/${notification.groupId}',
                                      );
                                    }
                                  },
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, List<AppNotification>> _group(List<AppNotification> items) {
    final locale = context.l10n.locale.languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<AppNotification>>{};
    for (final item in items) {
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      final key = date == today
          ? context.l10n.today
          : date == yesterday
          ? context.l10n.yesterday
          : AppDates.medium(date, localeCode: locale);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: context.texts.labelSmall?.copyWith(
          fontSize: 9,
          letterSpacing: 1.6,
          color: context.fair.inkMuted,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final (icon, tone) = switch (notification.kind) {
      AppNotificationKind.nudge => (Icons.waving_hand_rounded, fair.warning),
      AppNotificationKind.expenseAdded => (
        Icons.receipt_long_rounded,
        fair.accent,
      ),
      AppNotificationKind.settlementAdded => (
        Icons.handshake_rounded,
        fair.positive,
      ),
      AppNotificationKind.memberJoined => (
        Icons.person_add_alt_rounded,
        fair.blue,
      ),
      AppNotificationKind.reminder => (Icons.alarm_rounded, fair.info),
    };
    final unread = notification.isUnread;
    return FairCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: unread ? fair.accent.withValues(alpha: 0.35) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.13),
              borderRadius: AppRadius.allMd,
              border: Border.all(color: tone.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 20, color: tone),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: fair.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      AppDates.relative(
                        notification.createdAt,
                        localeCode: context.l10n.locale.languageCode,
                      ),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 0,
                        color: fair.inkMuted,
                      ),
                    ),
                    if (notification.actorName.isNotEmpty) ...[
                      Text(
                        ' · ${notification.actorName}',
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0,
                          color: fair.inkMuted,
                        ),
                      ),
                    ],
                    if (notification.isPending) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 12,
                        color: fair.warning,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: fair.inkMuted),
        ],
      ),
    );
  }
}
