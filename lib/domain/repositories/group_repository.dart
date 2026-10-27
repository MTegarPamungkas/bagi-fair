import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/group_invite.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';

class GroupJoinException implements Exception {
  const GroupJoinException(this.code);

  final String code;

  @override
  String toString() => code;
}

abstract interface class GroupRepository {
  Stream<List<Group>> watchGroups();

  Stream<Group?> watchGroup(String groupId);

  Stream<List<GroupMember>> watchMembers(String groupId);

  /// Used by the home overview to aggregate balances across every group.
  Stream<List<GroupMember>> watchAllMembers();

  Future<Group?> getGroup(String groupId);

  Future<void> createGroup(Group group);

  Future<void> updateGroup(Group group);

  Future<void> archiveGroup(String groupId);

  Future<GroupInvite> createInvite(String groupId);

  Future<void> joinGroup(String code);
}

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchExpenses(String groupId);

  /// Used by the home overview to aggregate balances across every group.
  Stream<List<Expense>> watchAllExpenses();

  Stream<Expense?> watchExpense(String expenseId);

  Future<Expense?> getExpense(String expenseId);

  Future<void> saveExpense(Expense expense);

  Future<void> deleteExpense(Expense expense);
}

abstract interface class SettlementRepository {
  Stream<List<Settlement>> watchSettlements(String groupId);

  /// Used by the home overview to aggregate balances across every group.
  Stream<List<Settlement>> watchAllSettlements();

  Future<void> saveSettlement(Settlement settlement);
}

abstract interface class ActivityRepository {
  Stream<List<ActivityEntry>> watchActivities(String groupId);

  Future<void> log(ActivityEntry entry);
}
