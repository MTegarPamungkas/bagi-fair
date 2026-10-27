import 'dart:async';

import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/shell/presentation/widgets/quick_add_sheet.dart';
import 'package:bagi_fair/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _unread = 0;
  StreamSubscription<int>? _unreadHandle;
  String? _boundUserId;

  @override
  void initState() {
    super.initState();
    _bindUnread();
  }

  void _bindUnread() {
    final user = getIt<AuthBloc>().state.user;
    if (user == null || user.id == _boundUserId) return;
    _boundUserId = user.id;
    _unreadHandle?.cancel();
    _unreadHandle = getIt<WatchUnreadNotifications>()(user.id).listen(
      (count) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _unread = count);
        });
      },
      onError: (Object error) {},
    );
  }

  @override
  void dispose() {
    _unreadHandle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final usesSide = context.usesSideNavigation;
    final index = widget.navigationShell.currentIndex;
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    final destinations = _destinations(l10n);
    _bindUnread();

    return Scaffold(
      backgroundColor: fair.background,
      body: Row(
        children: [
          if (usesSide)
            _SideRail(
              index: index,
              destinations: destinations,
              expanded: MediaQuery.sizeOf(context).width >= 1180,
              unread: _unread,
              user: user,
              onSelect: _onSelect,
              onAdd: () => _openQuickAdd(context, user),
            ),
          Expanded(
            child: SafeArea(
              bottom: !usesSide,
              child: Column(
                children: [
                  if (!usesSide)
                    _MobileTopBar(
                      user: user,
                      onAccount: () => _onSelect(3),
                    ),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: usesSide
          ? null
          : _BottomDock(
              index: index,
              destinations: destinations,
              unread: _unread,
              onSelect: _onSelect,
            ),
      floatingActionButton: usesSide || user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openQuickAdd(context, user),
              tooltip: l10n.add,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l10n.t('Catat', 'Add'),
                style: context.texts.labelLarge?.copyWith(
                  color: fair.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _openQuickAdd(BuildContext context, AppUser? user) {
    if (user == null) return;
    showQuickAddSheet(context);
  }

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<_Destination> _destinations(AppLocalizations l10n) => [
    _Destination(
      label: l10n.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _Destination(
      label: l10n.groups,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    _Destination(
      label: l10n.notifications,
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _Destination(
      label: l10n.you,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Slim brand strip on phones. It replaces the old duplicated title bar: the
/// page below already owns the heading, so this only carries identity + account.
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.user,
    required this.onAccount,
  });

  final AppUser? user;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Container(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 8, context.pagePadding, 8),
      decoration: BoxDecoration(
        color: fair.background,
        border: Border(bottom: BorderSide(color: fair.line)),
      ),
      child: Row(
        children: [
          const FairLogo(size: 30),
          const SizedBox(width: 9),
          Text(
            context.l10n.appName,
            style: AppTypography.heading(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fair.ink,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          const _ShellSyncChip(compact: true),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            borderRadius: AppRadius.allPill,
            onTap: onAccount,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AvatarCircle(
                name: user?.displayName ?? context.l10n.you,
                imageUrl: user?.avatarUrl,
                size: 32,
                highlight: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.index,
    required this.destinations,
    required this.unread,
    required this.onSelect,
  });

  final int index;
  final List<_Destination> destinations;
  final int unread;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Container(
      decoration: BoxDecoration(
        color: fair.surface,
        border: Border(top: BorderSide(color: fair.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _DockItem(
                    destination: destinations[i],
                    selected: i == index,
                    badge: i == 2 ? unread : 0,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = selected ? fair.accent : fair.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: selected ? fair.accentSoft : Colors.transparent,
              borderRadius: AppRadius.allPill,
            ),
            child: Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 21,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelMedium?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.expanded,
    required this.unread,
    required this.user,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final List<_Destination> destinations;
  final bool expanded;
  final int unread;
  final AppUser? user;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final width = expanded ? 236.0 : 86.0;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: fair.surface,
        border: Border(right: BorderSide(color: fair.line)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 18 : 16,
                20,
                expanded ? 18 : 16,
                18,
              ),
              child: expanded
                  ? const FairLogo(size: 36, showWordmark: true)
                  : const Center(child: FairLogo(size: 36)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12),
              child: expanded
                  ? FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l10n.t('Catat', 'Add')),
                    )
                  : IconButton.filled(
                      onPressed: onAdd,
                      tooltip: context.l10n.add,
                      icon: const Icon(Icons.add_rounded),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < destinations.length; i++)
              _RailItem(
                destination: destinations[i],
                selected: i == index,
                expanded: expanded,
                badge: i == 2 ? unread : 0,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12),
              child: Divider(color: fair.line),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 14 : 10,
                8,
                expanded ? 14 : 10,
                16,
              ),
              child: expanded
                  ? Row(
                      children: [
                        const _ShellSyncChip(compact: false),
                        const Spacer(),
                        AvatarCircle(
                          name: user?.displayName ?? context.l10n.you,
                          imageUrl: user?.avatarUrl,
                          size: 30,
                          highlight: true,
                        ),
                      ],
                    )
                  : const Center(child: _ShellSyncChip(compact: true)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.badge,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool expanded;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final foreground = selected ? fair.ink : fair.inkMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 9, vertical: 2),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? fair.accentSoft : Colors.transparent,
            borderRadius: AppRadius.allMd,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 20,
                      color: selected ? fair.accent : foreground,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (badge > 0)
                      Badge(
                        label: Text('$badge'),
                        child: const SizedBox.shrink(),
                      ),
                  ],
                )
              : Tooltip(
                  message: destination.label,
                  child: Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 21,
                      color: selected ? fair.accent : foreground,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ShellSyncChip extends StatelessWidget {
  const _ShellSyncChip({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncStatus>(
      builder: (context, status) => SyncChip(
        status: status,
        expanded: !compact,
        onTap: status.phase == SyncPhase.syncing
            ? null
            : () => context.read<SyncBloc>().add(const SyncRequested()),
      ),
    );
  }
}
