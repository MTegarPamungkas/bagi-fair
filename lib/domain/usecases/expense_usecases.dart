import 'dart:typed_data';

import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/entities/receipt_scan.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/repositories/receipt_repository.dart';
import 'package:bagi_fair/domain/usecases/balance_calculator.dart';

class WatchExpenses {
  const WatchExpenses(this._repository);

  final ExpenseRepository _repository;

  Stream<List<Expense>> call(String groupId) =>
      _repository.watchExpenses(groupId);
}

class WatchExpense {
  const WatchExpense(this._repository);

  final ExpenseRepository _repository;

  Stream<Expense?> call(String expenseId) =>
      _repository.watchExpense(expenseId);
}

class GetExpense {
  const GetExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Expense?> call(String expenseId) => _repository.getExpense(expenseId);
}

class SaveExpense {
  const SaveExpense(this._repository);

  final ExpenseRepository _repository;

  Future<void> call(Expense expense) => _repository.saveExpense(expense);
}

class DeleteExpense {
  const DeleteExpense(this._repository);

  final ExpenseRepository _repository;

  Future<void> call(Expense expense) => _repository.deleteExpense(expense);
}

class WatchSettlements {
  const WatchSettlements(this._repository);

  final SettlementRepository _repository;

  Stream<List<Settlement>> call(String groupId) =>
      _repository.watchSettlements(groupId);
}

class SaveSettlement {
  const SaveSettlement(this._repository);

  final SettlementRepository _repository;

  Future<void> call(Settlement settlement) =>
      _repository.saveSettlement(settlement);
}

class WatchActivities {
  const WatchActivities(this._repository);

  final ActivityRepository _repository;

  Stream<List<ActivityEntry>> call(String groupId) =>
      _repository.watchActivities(groupId);
}

class LogActivity {
  const LogActivity(this._repository);

  final ActivityRepository _repository;

  Future<void> call(ActivityEntry entry) => _repository.log(entry);
}

class WatchReceipts {
  const WatchReceipts(this._repository);

  final ReceiptRepository _repository;

  Stream<List<Receipt>> call(String groupId) =>
      _repository.watchReceipts(groupId);
}

class GetReceipt {
  const GetReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<Receipt?> call(String receiptId) => _repository.getReceipt(receiptId);
}

class SaveReceipt {
  const SaveReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<void> call(Receipt receipt) => _repository.saveReceipt(receipt);
}

class ScanReceipt {
  const ScanReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<ReceiptScan> call({
    required Uint8List bytes,
    required String mimeType,
    required String groupId,
    required String localeCode,
  }) => _repository.scan(
    bytes: bytes,
    mimeType: mimeType,
    groupId: groupId,
    localeCode: localeCode,
  );
}

class UploadReceiptImage {
  const UploadReceiptImage(this._repository);

  final ReceiptRepository _repository;

  Future<String?> call({
    required String groupId,
    required String receiptId,
    required Uint8List bytes,
  }) => _repository.uploadImage(
    groupId: groupId,
    receiptId: receiptId,
    bytes: bytes,
  );
}

class ComputeGroupBalance {
  const ComputeGroupBalance();

  GroupBalanceSummary call({
    required List<GroupMember> members,
    required List<Expense> expenses,
    required List<Settlement> settlements,
    String? currentUserId,
  }) {
    return BalanceCalculator.compute(
      members: members,
      expenses: expenses,
      settlements: settlements,
      currentUserId: currentUserId,
    );
  }
}
