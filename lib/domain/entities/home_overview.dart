import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:equatable/equatable.dart';

class GroupOverview extends Equatable {
  const GroupOverview({
    required this.group,
    required this.members,
    required this.summary,
    required this.expenseCount,
  });

  final Group group;
  final List<GroupMember> members;
  final GroupBalanceSummary summary;
  final int expenseCount;

  GroupMember? memberFor(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  String nameFor(String userId) =>
      memberFor(userId)?.displayName ??
      (userId.length > 8 ? userId.substring(0, 8) : userId);

  @override
  List<Object?> get props => [group, members, summary, expenseCount];
}

class HomeOverview extends Equatable {
  const HomeOverview({
    this.groups = const [],
    this.recentExpenses = const [],
    this.totalSpendMinor = 0,
    this.youOweMinor = 0,
    this.youAreOwedMinor = 0,
  });

  final List<GroupOverview> groups;
  final List<Expense> recentExpenses;
  final int totalSpendMinor;
  final int youOweMinor;
  final int youAreOwedMinor;

  int get netMinor => youAreOwedMinor - youOweMinor;

  bool get isImpas => youOweMinor == 0 && youAreOwedMinor == 0;

  @override
  List<Object?> get props => [
    groups,
    recentExpenses,
    totalSpendMinor,
    youOweMinor,
    youAreOwedMinor,
  ];
}
