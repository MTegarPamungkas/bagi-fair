import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';

class GroupExportRequest {
  const GroupExportRequest({
    required this.group,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.summary,
    required this.activities,
    required this.localeCode,
    this.currentUserId,
  });

  final String? currentUserId;

  final Group group;
  final List<GroupMember> members;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final GroupBalanceSummary summary;
  final List<ActivityEntry> activities;
  final String localeCode;
}

abstract interface class ExportRepository {
  Future<void> exportCsv(GroupExportRequest request);

  Future<void> exportPdf(GroupExportRequest request);
}
