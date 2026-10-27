import 'package:equatable/equatable.dart';

enum SyncPhase { idle, syncing, offline, error, demo }

class SyncStatus extends Equatable {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get isDemo => phase == SyncPhase.demo;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  static const demo = SyncStatus(phase: SyncPhase.demo);

  @override
  List<Object?> get props => [phase, pendingCount, lastSyncedAt, message];
}
