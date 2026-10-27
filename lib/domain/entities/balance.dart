import 'package:equatable/equatable.dart';

class MemberBalance extends Equatable {
  const MemberBalance({
    required this.userId,
    required this.netMinor,
    required this.paidMinor,
    required this.owedMinor,
  });

  final String userId;

  /// Positive means the group owes this person; negative means they owe.
  final int netMinor;
  final int paidMinor;
  final int owedMinor;

  bool get isImpas => netMinor == 0;

  @override
  List<Object?> get props => [userId, netMinor, paidMinor, owedMinor];
}

class TransferSuggestion extends Equatable {
  const TransferSuggestion({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;

  @override
  List<Object?> get props => [fromUserId, toUserId, amountMinor];
}

class GroupBalanceSummary extends Equatable {
  const GroupBalanceSummary({
    this.balances = const [],
    this.transfers = const [],
    this.totalExpenseMinor = 0,
    this.yourShareMinor = 0,
    this.youOweMinor = 0,
    this.youAreOwedMinor = 0,
    this.isImpas = true,
  });

  final List<MemberBalance> balances;
  final List<TransferSuggestion> transfers;
  final int totalExpenseMinor;
  final int yourShareMinor;
  final int youOweMinor;
  final int youAreOwedMinor;
  final bool isImpas;

  MemberBalance? balanceFor(String userId) {
    for (final balance in balances) {
      if (balance.userId == userId) return balance;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    balances,
    transfers,
    totalExpenseMinor,
    yourShareMinor,
    youOweMinor,
    youAreOwedMinor,
    isImpas,
  ];
}
