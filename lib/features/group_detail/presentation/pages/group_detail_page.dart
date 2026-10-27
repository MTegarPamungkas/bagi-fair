import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/group_activity_tab.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/group_balances_tab.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/group_detail_header.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/group_expenses_tab.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/invite_sheet.dart';
import 'package:bagi_fair/features/group_detail/presentation/widgets/nudge_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupDetailBloc>()..add(GroupDetailStarted(groupId)),
      child: _GroupDetailView(groupId: groupId),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  const _GroupDetailView({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      listenWhen: (previous, current) =>
          previous.actionError != current.actionError ||
          previous.actionNotice != current.actionNotice ||
          previous.nudgeText != current.nudgeText,
      listener: (context, state) {
        final bloc = context.read<GroupDetailBloc>();
        if (state.actionError != null) {
          showFairSnack(context, _error(context, state.actionError!));
          bloc.add(const GroupDetailMessageDismissed());
        }
        if (state.actionNotice != null) {
          showFairSnack(context, _notice(context, state.actionNotice!));
          bloc.add(const GroupDetailMessageDismissed());
        }
        if (state.nudgeText != null) {
          showNudgeSheet(
            context,
            targetName: state.nudgeTargetName ?? '',
            message: state.nudgeText!,
          );
          bloc.add(const GroupDetailMessageDismissed());
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: state.group == null
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => context.push(
                      '/groups/${state.group!.id}/expenses/new',
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(context.l10n.addExpense),
                  ),
            body: FairBackground(
              child: SafeArea(
                top: false,
                child: state.loading && state.group == null
                    ? const LoadingState()
                    : state.group == null
                    ? ErrorState(
                        message: state.error ?? context.l10n.groupNotFound,
                        onRetry: () => context.read<GroupDetailBloc>().add(
                          GroupDetailStarted(groupId),
                        ),
                      )
                    : _Content(state: state),
              ),
            ),
          ),
        );
      },
    );
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'settle_failed' => l10n.settleFailed,
      'nudge_already_even' => l10n.nudgeAlreadyEven,
      'share_failed' => l10n.shareFailed,
      'save_failed' => l10n.saveFailed,
      _ => l10n.somethingWrong,
    };
  }

  String _notice(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'settlement_saved' => l10n.settlementSaved,
      'expense_deleted' => l10n.expenseDeleted,
      'group_archived' => l10n.groupArchived,
      'exported_csv' => l10n.exportedCsv,
      'exported_pdf' => l10n.exportedPdf,
      _ => l10n.done,
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final GroupDetailState state;

  @override
  Widget build(BuildContext context) {
    final group = state.group!;
    final l10n = context.l10n;
    final fair = context.fair;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                4,
                context.pagePadding,
                0,
              ),
              child: Column(
                children: [
                  GroupDetailHeader(
                    state: state,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/groups');
                      }
                    },
                    onInvite: () => showInviteSheet(
                      context,
                      groupId: group.id,
                      groupName: group.name,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: fair.surface,
                      borderRadius: AppRadius.allPill,
                      border: Border.all(color: fair.line),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: fair.accentSoft,
                        borderRadius: AppRadius.allPill,
                      ),
                      labelColor: fair.accent,
                      unselectedLabelColor: fair.inkMuted,
                      labelStyle: context.texts.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                      unselectedLabelStyle: context.texts.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      tabs: [
                        Tab(height: 36, text: l10n.expenses),
                        Tab(height: 36, text: l10n.balances),
                        Tab(height: 36, text: l10n.activity),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: TabBarView(
                children: [
                  GroupExpensesTab(state: state),
                  GroupBalancesTab(state: state),
                  GroupActivityTab(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
