import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/usecases/debt_simplifier.dart';

abstract final class BalanceCalculator {
  static GroupBalanceSummary compute({
    required List<GroupMember> members,
    required List<Expense> expenses,
    required List<Settlement> settlements,
    String? currentUserId,
  }) {
    final paid = <String, int>{for (final member in members) member.userId: 0};
    final owed = <String, int>{for (final member in members) member.userId: 0};
    var totalExpense = 0;
    var yourShare = 0;

    for (final expense in expenses) {
      totalExpense += expense.amountBaseMinor;
      if (paid.containsKey(expense.paidBy)) {
        paid[expense.paidBy] = paid[expense.paidBy]! + expense.amountBaseMinor;
      }
      for (final share in expense.shares) {
        if (!owed.containsKey(share.userId)) continue;
        owed[share.userId] = owed[share.userId]! + share.amountMinor;
        if (share.userId == currentUserId) {
          yourShare += share.amountMinor;
        }
      }
    }

    for (final settlement in settlements) {
      if (paid.containsKey(settlement.fromUserId)) {
        paid[settlement.fromUserId] =
            paid[settlement.fromUserId]! + settlement.amountMinor;
      }
      if (owed.containsKey(settlement.toUserId)) {
        owed[settlement.toUserId] =
            owed[settlement.toUserId]! + settlement.amountMinor;
      }
    }

    final balances = <MemberBalance>[
      for (final member in members)
        MemberBalance(
          userId: member.userId,
          netMinor: (paid[member.userId] ?? 0) - (owed[member.userId] ?? 0),
          paidMinor: paid[member.userId] ?? 0,
          owedMinor: owed[member.userId] ?? 0,
        ),
    ];

    final transfers = DebtSimplifier.simplify(balances);
    MemberBalance? mine;
    for (final balance in balances) {
      if (balance.userId == currentUserId) {
        mine = balance;
        break;
      }
    }

    return GroupBalanceSummary(
      balances: balances,
      transfers: transfers,
      totalExpenseMinor: totalExpense,
      yourShareMinor: yourShare,
      youOweMinor: mine != null && mine.netMinor < 0 ? -mine.netMinor : 0,
      youAreOwedMinor: mine != null && mine.netMinor > 0 ? mine.netMinor : 0,
      isImpas: balances.every((balance) => balance.netMinor == 0),
    );
  }
}
