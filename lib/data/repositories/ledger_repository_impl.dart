import 'dart:typed_data';

import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/entities/receipt_scan.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:bagi_fair/domain/repositories/receipt_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._store, this._queue);

  final LocalStore _store;
  final MutationQueue _queue;

  @override
  Stream<List<Expense>> watchExpenses(String groupId) {
    return _store.watch('expenses').map((rows) {
      final expenses = <Expense>[];
      for (final row in rows) {
        if (row['group_id'] != groupId || row['deleted_at'] != null) continue;
        expenses.add(Expense.fromJson(row));
      }
      expenses.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return expenses;
    });
  }

  @override
  Stream<List<Expense>> watchAllExpenses() {
    return _store.watch('expenses').map((rows) {
      final expenses = <Expense>[];
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        expenses.add(Expense.fromJson(row));
      }
      return expenses;
    });
  }

  @override
  Stream<Expense?> watchExpense(String expenseId) {
    return _store.watch('expenses').map((rows) {
      for (final row in rows) {
        if (row['id'] == expenseId && row['deleted_at'] == null) {
          return Expense.fromJson(row);
        }
      }
      return null;
    });
  }

  @override
  Future<Expense?> getExpense(String expenseId) async {
    final row = _store.get('expenses', expenseId);
    if (row == null || row['deleted_at'] != null) return null;
    return Expense.fromJson(row);
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final row = expense.toJson();
    await _store.put('expenses', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'expenses',
      rowId: expense.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }

  @override
  Future<void> deleteExpense(Expense expense) async {
    await _store.delete('expenses', expense.id);
    await _queue.enqueue(
      table: 'expenses',
      rowId: expense.id,
      operation: OutboxOperation.delete,
      payload: {
        'id': expense.id,
        'group_id': expense.groupId,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}

class SettlementRepositoryImpl implements SettlementRepository {
  SettlementRepositoryImpl(this._store, this._queue);

  final LocalStore _store;
  final MutationQueue _queue;

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) {
    return _store.watch('settlements').map((rows) {
      final settlements = <Settlement>[];
      for (final row in rows) {
        if (row['group_id'] != groupId || row['deleted_at'] != null) continue;
        settlements.add(Settlement.fromJson(row));
      }
      settlements.sort((a, b) => b.settledAt.compareTo(a.settledAt));
      return settlements;
    });
  }

  @override
  Stream<List<Settlement>> watchAllSettlements() {
    return _store.watch('settlements').map((rows) {
      final settlements = <Settlement>[];
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        settlements.add(Settlement.fromJson(row));
      }
      return settlements;
    });
  }

  @override
  Future<void> saveSettlement(Settlement settlement) async {
    final row = settlement.toJson();
    await _store.put('settlements', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'settlements',
      rowId: settlement.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }
}

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._store, this._queue);

  final LocalStore _store;
  final MutationQueue _queue;

  @override
  Stream<List<ActivityEntry>> watchActivities(String groupId) {
    return _store.watch('activities').map((rows) {
      final activities = <ActivityEntry>[];
      for (final row in rows) {
        if (row['group_id'] != groupId || row['deleted_at'] != null) continue;
        activities.add(ActivityEntry.fromJson(row));
      }
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activities;
    });
  }

  @override
  Future<void> log(ActivityEntry entry) async {
    final row = entry.toJson();
    await _store.put('activities', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'activities',
      rowId: entry.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }
}

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._store, this._queue, this._gateway);

  final LocalStore _store;
  final MutationQueue _queue;
  final CloudGateway _gateway;

  @override
  Stream<List<Receipt>> watchReceipts(String groupId) {
    return _store.watch('receipts').map((rows) {
      final receipts = <Receipt>[];
      for (final row in rows) {
        if (row['group_id'] != groupId || row['deleted_at'] != null) continue;
        receipts.add(Receipt.fromJson(row));
      }
      receipts.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return receipts;
    });
  }

  @override
  Future<Receipt?> getReceipt(String receiptId) async {
    final row = _store.get('receipts', receiptId);
    if (row == null || row['deleted_at'] != null) return null;
    return Receipt.fromJson(row);
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    final row = receipt.toJson();
    await _store.put('receipts', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'receipts',
      rowId: receipt.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }

  @override
  Future<ReceiptScan> scan({
    required Uint8List bytes,
    required String mimeType,
    required String groupId,
    required String localeCode,
  }) {
    return _gateway.scanReceipt(
      bytes: bytes,
      mimeType: mimeType,
      groupId: groupId,
      localeCode: localeCode,
    );
  }

  @override
  Future<String?> uploadImage({
    required String groupId,
    required String receiptId,
    required Uint8List bytes,
  }) {
    return _gateway.uploadReceipt(
      groupId: groupId,
      receiptId: receiptId,
      bytes: bytes,
    );
  }
}
