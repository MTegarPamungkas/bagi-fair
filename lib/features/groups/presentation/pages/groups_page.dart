import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:bagi_fair/features/groups/presentation/widgets/group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    return BlocProvider(
      create: (_) => getIt<GroupsBloc>()
        ..add(GroupsStarted(userId: user?.id ?? '')),
      child: const _GroupsView(),
    );
  }
}

class _GroupsView extends StatefulWidget {
  const _GroupsView();

  @override
  State<_GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<_GroupsView> {
  GroupType? _type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final padding = context.pagePadding;
    return FairBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(padding, 18, padding, 120),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    eyebrow: l10n.groups,
                    title: l10n.groupsTitle,
                    subtitle: l10n.groupsSubtitle,
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/groups/join'),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: Text(l10n.joinGroup),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.push('/groups/new'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.newGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    onChanged: (value) => context.read<GroupsBloc>().add(
                      GroupsQueryChanged(value),
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(
                        label: l10n.all,
                        selected: _type == null,
                        onTap: () => setState(() => _type = null),
                      ),
                      for (final type in GroupType.values)
                        Pill(
                          label: l10n.groupTypeName(type),
                          selected: _type == type,
                          onTap: () => setState(() => _type = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BlocConsumer<GroupsBloc, GroupsState>(
                    listenWhen: (previous, current) =>
                        previous.error != current.error,
                    listener: (context, state) {
                      if (state.error != null) {
                        showFairSnack(context, l10n.loadFailed);
                      }
                    },
                    builder: (context, state) {
                      if (state.loading) {
                        return const LoadingState();
                      }
                      final groups = state.filtered
                          .where(
                            (group) => _type == null || group.type == _type,
                          )
                          .toList(growable: false);
                      if (state.groups.isEmpty) {
                        return EmptyState(
                          icon: Icons.groups_2_outlined,
                          title: l10n.noGroups,
                          body: l10n.noGroupsBody,
                          action: FilledButton.icon(
                            onPressed: () => context.push('/groups/new'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.createFirstGroup),
                          ),
                        );
                      }
                      if (groups.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: l10n.noGroups,
                          body: l10n.groupsSubtitle,
                        );
                      }
                      return _Grid(
                        groups: groups,
                        netByGroup: state.netByGroup,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.groups, required this.netByGroup});

  final List<Group> groups;
  final Map<String, int> netByGroup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final group in groups)
              SizedBox(
                width: width,
                child: GroupCard(
                  group: group,
                  netMinor: netByGroup[group.id],
                  onTap: () => context.push('/groups/${group.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
