import 'package:bagi_fair/core/utils/stream_combine.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/usecases/balance_calculator.dart';

/// Projects every group, member, expense and settlement in the local cache into
/// the home dashboard. The cache already holds the server snapshot, so this is
/// also the realtime path.
class WatchHomeOverview {
  const WatchHomeOverview(this._groups, this._expenses, this._settlements);

  final GroupRepository _groups;
  final ExpenseRepository _expenses;
  final SettlementRepository _settlements;

  Stream<HomeOverview> call({String? currentUserId}) {
    return combineLatest4(
      _groups.watchGroups(),
      _groups.watchAllMembers(),
      _expenses.watchAllExpenses(),
      _settlements.watchAllSettlements(),
      (
        List<Group> groups,
        List<GroupMember> members,
        List<Expense> expenses,
        List<Settlement> settlements,
      ) {
        final overviews = <GroupOverview>[];
        var totalSpend = 0;
        var youOwe = 0;
        var youAreOwed = 0;

        for (final group in groups) {
          final groupMembers = members
              .where((member) => member.groupId == group.id)
              .toList(growable: false);
          final groupExpenses = expenses
              .where((expense) => expense.groupId == group.id)
              .toList(growable: false);
          final groupSettlements = settlements
              .where((settlement) => settlement.groupId == group.id)
              .toList(growable: false);
          final summary = BalanceCalculator.compute(
            members: groupMembers,
            expenses: groupExpenses,
            settlements: groupSettlements,
            currentUserId: currentUserId,
          );
          totalSpend += summary.totalExpenseMinor;
          youOwe += summary.youOweMinor;
          youAreOwed += summary.youAreOwedMinor;
          overviews.add(
            GroupOverview(
              group: group,
              members: groupMembers,
              summary: summary,
              expenseCount: groupExpenses.length,
            ),
          );
        }

        final recent = [...expenses]
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

        return HomeOverview(
          groups: overviews,
          recentExpenses: recent.take(5).toList(growable: false),
          totalSpendMinor: totalSpend,
          youOweMinor: youOwe,
          youAreOwedMinor: youAreOwed,
        );
      },
    );
  }
}
