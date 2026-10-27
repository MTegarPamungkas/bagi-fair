import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/usecases/balance_calculator.dart';
import 'package:bagi_fair/domain/usecases/debt_simplifier.dart';
import 'package:flutter_test/flutter_test.dart';

GroupMember _member(String id) => GroupMember(
  id: 'm_$id',
  groupId: 'g1',
  userId: id,
  displayName: id.toUpperCase(),
  role: GroupRole.member,
  joinedAt: DateTime(2026, 1, 1),
);

Expense _expense({
  required String id,
  required String paidBy,
  required int amount,
  required Map<String, int> shares,
}) {
  return Expense(
    id: id,
    groupId: 'g1',
    title: 'Makan',
    amountMinor: amount,
    amountBaseMinor: amount,
    currency: 'IDR',
    paidBy: paidBy,
    splitMode: SplitMode.exact,
    occurredAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    createdBy: paidBy,
    shares: [
      for (final entry in shares.entries)
        ExpenseShare(userId: entry.key, amountMinor: entry.value),
    ],
  );
}

void main() {
  group('debt simplifier', () {
    test('never needs more than n-1 transfers', () {
      final balances = const [
        MemberBalance(
          userId: 'a',
          netMinor: -500,
          paidMinor: 0,
          owedMinor: 500,
        ),
        MemberBalance(
          userId: 'b',
          netMinor: -300,
          paidMinor: 0,
          owedMinor: 300,
        ),
        MemberBalance(userId: 'c', netMinor: 500, paidMinor: 500, owedMinor: 0),
        MemberBalance(userId: 'd', netMinor: 300, paidMinor: 300, owedMinor: 0),
      ];
      final transfers = DebtSimplifier.simplify(balances);
      expect(transfers.length, 2);
      expect(
        transfers.fold(0, (sum, transfer) => sum + transfer.amountMinor),
        800,
      );
    });

    test('returns nothing when everyone is impas', () {
      final transfers = DebtSimplifier.simplify(const [
        MemberBalance(userId: 'a', netMinor: 0, paidMinor: 100, owedMinor: 100),
        MemberBalance(userId: 'b', netMinor: 0, paidMinor: 50, owedMinor: 50),
      ]);
      expect(transfers, isEmpty);
    });

    test('settles a chain with the fewest obvious transfers', () {
      final transfers = DebtSimplifier.simplify(const [
        MemberBalance(
          userId: 'a',
          netMinor: -100,
          paidMinor: 0,
          owedMinor: 100,
        ),
        MemberBalance(
          userId: 'b',
          netMinor: -100,
          paidMinor: 0,
          owedMinor: 100,
        ),
        MemberBalance(userId: 'c', netMinor: 50, paidMinor: 50, owedMinor: 0),
        MemberBalance(userId: 'd', netMinor: 150, paidMinor: 150, owedMinor: 0),
      ]);
      expect(transfers.length, 3);
      expect(transfers.fold(0, (sum, t) => sum + t.amountMinor), 200);
    });
  });

  group('balance calculator', () {
    test('derives net balances, your share, and transfers', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [
        _expense(
          id: 'e1',
          paidBy: 'a',
          amount: 90000,
          shares: const {'a': 30000, 'b': 30000, 'c': 30000},
        ),
      ];
      final summary = BalanceCalculator.compute(
        members: members,
        expenses: expenses,
        settlements: const [],
        currentUserId: 'b',
      );

      expect(summary.totalExpenseMinor, 90000);
      expect(summary.yourShareMinor, 30000);
      expect(summary.youOweMinor, 30000);
      expect(summary.youAreOwedMinor, 0);
      expect(summary.isImpas, false);
      expect(summary.transfers.length, 2);
      expect(
        summary.balances.firstWhere((b) => b.userId == 'a').netMinor,
        60000,
      );
    });

    test('settlements reduce the outstanding balance to impas', () {
      final members = [_member('a'), _member('b')];
      final expenses = [
        _expense(
          id: 'e1',
          paidBy: 'a',
          amount: 50000,
          shares: const {'a': 25000, 'b': 25000},
        ),
      ];
      final settlements = [
        Settlement(
          id: 's1',
          groupId: 'g1',
          fromUserId: 'b',
          toUserId: 'a',
          amountMinor: 25000,
          currency: 'IDR',
          settledAt: DateTime(2026, 1, 2),
          createdBy: 'b',
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];
      final summary = BalanceCalculator.compute(
        members: members,
        expenses: expenses,
        settlements: settlements,
      );
      expect(summary.isImpas, true);
      expect(summary.transfers, isEmpty);
      expect(summary.balances.map((balance) => balance.netMinor), [0, 0]);
    });
  });
}
