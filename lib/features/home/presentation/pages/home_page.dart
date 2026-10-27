import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/home/presentation/bloc/home_bloc.dart';
import 'package:bagi_fair/features/home/presentation/widgets/home_balance_card.dart';
import 'package:bagi_fair/features/home/presentation/widgets/home_group_list.dart';
import 'package:bagi_fair/features/home/presentation/widgets/home_recent_expenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    return BlocProvider(
      create: (_) {
        final bloc = getIt<HomeBloc>();
        if (user != null) bloc.add(HomeStarted(userId: user.id));
        return bloc;
      },
      child: _HomeView(user: user),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) {
          showFairSnack(context, context.l10n.loadFailed);
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final fair = context.fair;
        final overview = state.overview;
        final padding = context.pagePadding;
        final loading = state.loading && overview.groups.isEmpty;

        return FairBackground(
          child: RefreshIndicator(
            color: fair.accent,
            onRefresh: () async {
              context.read<HomeBloc>().add(const HomeRefreshRequested());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          eyebrow: l10n.homeEyebrow,
                          title: user == null
                              ? l10n.homeTitle
                              : l10n.greeting(user!.displayName),
                          subtitle: l10n.t(
                            'Ini posisi kamu hari ini. Ketuk angka mana pun untuk melihat asalnya.',
                            'Your position today. Tap any number to see where it comes from.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (loading)
                          const LoadingState()
                        else ...[
                          HomeBalanceCard(overview: overview),
                          const SizedBox(height: AppSpacing.xl),
                          if (overview.groups.isEmpty)
                            EmptyState(
                              icon: Icons.groups_2_outlined,
                              title: l10n.noGroups,
                              body: l10n.noGroupsBody,
                              action: FilledButton.icon(
                                onPressed: () => context.push('/groups/new'),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(l10n.createFirstGroup),
                              ),
                            )
                          else ...[
                            SectionHeader(
                              title: l10n.activeGroups,
                              subtitle: l10n.acrossGroups,
                              action: TextButton(
                                onPressed: () => context.go('/groups'),
                                child: Text(l10n.seeAll),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            HomeGroupList(
                              groups: overview.groups,
                              onOpen: (group) =>
                                  context.push('/groups/${group.group.id}'),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            title: l10n.recentExpenses,
                            action: overview.groups.isEmpty
                                ? null
                                : TextButton(
                                    onPressed: () => context.go('/groups'),
                                    child: Text(l10n.seeAll),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (overview.recentExpenses.isEmpty)
                            EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: l10n.noExpenses,
                              body: l10n.noExpensesBody,
                              padding: AppSpacing.lg,
                            )
                          else
                            HomeRecentExpenses(
                              expenses: overview.recentExpenses,
                              groups: overview.groups,
                              user: user,
                              onOpenGroup: (groupId) =>
                                  context.push('/groups/$groupId'),
                            ),
                          if (state.notifications.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            SectionHeader(
                              title: l10n.notifications,
                              action: TextButton(
                                onPressed: () => context.go('/notifications'),
                                child: Text(l10n.seeAll),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            HomeNotificationPreview(
                              notifications: state.notifications
                                  .take(3)
                                  .toList(growable: false),
                              onOpen: (notification) => context
                                  .read<HomeBloc>()
                                  .add(HomeNotificationsRead(notification)),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          Center(
                            child: Text(
                              l10n.tagline,
                              style: context.texts.bodySmall?.copyWith(
                                fontFamily: AppTypography.mono,
                                fontSize: 10,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
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
}
