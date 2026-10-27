import 'package:bagi_fair/domain/entities/expense.dart';

enum SplitFailure {
  totalNotPositive,
  emptyParticipants,
  percentageNotHundred,
  exactMismatch,
  noItems,
  itemWithoutOwner,
  invalidItem,
  totalBelowDiscount,
}

class SplitException implements Exception {
  const SplitException(this.failure, {this.detail});

  final SplitFailure failure;
  final String? detail;

  @override
  String toString() =>
      'SplitException($failure${detail == null ? '' : ': $detail'})';
}

class SplitParticipant {
  const SplitParticipant({
    required this.userId,
    this.weightBps = 0,
    this.exactMinor = 0,
  });

  final String userId;

  /// Percentage basis points (10000 = 100%).
  final int weightBps;

  /// Fixed amount for exact mode, in the same currency as the total.
  final int exactMinor;
}

class SplitResult {
  const SplitResult({
    required this.shares,
    required this.amountMinor,
    required this.subtotalMinor,
    this.taxMinor = 0,
    this.serviceMinor = 0,
    this.discountMinor = 0,
    this.adjustmentMinor = 0,
  });

  final List<ExpenseShare> shares;
  final int amountMinor;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceMinor;
  final int discountMinor;

  /// Difference between the receipt's declared total and the item math.
  final int adjustmentMinor;
}

/// Deterministic integer money splitting.
///
/// Every mode must produce shares that sum exactly to the expense total. The
/// largest-remainder allocator handles odd rupiah/cents without ever losing a
/// unit or pushing a share over by a full unit.
abstract final class SplitEngine {
  static SplitResult compute({
    required int totalMinor,
    required SplitMode mode,
    required List<SplitParticipant> participants,
    List<ExpenseItem> items = const [],
    int taxMinor = 0,
    int serviceMinor = 0,
    int discountMinor = 0,
  }) {
    if (totalMinor <= 0) {
      throw const SplitException(SplitFailure.totalNotPositive);
    }
    if (taxMinor < 0 || serviceMinor < 0 || discountMinor < 0) {
      throw const SplitException(SplitFailure.invalidItem);
    }
    if (discountMinor > totalMinor) {
      throw const SplitException(SplitFailure.totalBelowDiscount);
    }

    switch (mode) {
      case SplitMode.equal:
        return _equal(totalMinor, participants);
      case SplitMode.percentage:
        return _percentage(totalMinor, participants);
      case SplitMode.exact:
        return _exact(totalMinor, participants);
      case SplitMode.itemized:
        return _itemized(
          totalMinor: totalMinor,
          participants: participants,
          items: items,
          taxMinor: taxMinor,
          serviceMinor: serviceMinor,
          discountMinor: discountMinor,
        );
    }
  }

  static SplitResult _equal(int total, List<SplitParticipant> participants) {
    _requireParticipants(participants);
    final weights = List<int>.filled(participants.length, 1);
    final amounts = allocate(total, weights);
    return SplitResult(
      amountMinor: total,
      subtotalMinor: total,
      shares: [
        for (var i = 0; i < participants.length; i++)
          ExpenseShare(
            userId: participants[i].userId,
            amountMinor: amounts[i],
            subtotalMinor: amounts[i],
            weightBps: 10000 ~/ participants.length,
          ),
      ],
    );
  }

  static SplitResult _percentage(
    int total,
    List<SplitParticipant> participants,
  ) {
    _requireParticipants(participants);
    final sum = participants.fold(0, (value, item) => value + item.weightBps);
    if (sum != 10000) {
      throw SplitException(
        SplitFailure.percentageNotHundred,
        detail: '$sum bps',
      );
    }
    final amounts = allocate(
      total,
      participants.map((participant) => participant.weightBps).toList(),
    );
    return SplitResult(
      amountMinor: total,
      subtotalMinor: total,
      shares: [
        for (var i = 0; i < participants.length; i++)
          ExpenseShare(
            userId: participants[i].userId,
            amountMinor: amounts[i],
            subtotalMinor: amounts[i],
            weightBps: participants[i].weightBps,
          ),
      ],
    );
  }

  static SplitResult _exact(int total, List<SplitParticipant> participants) {
    _requireParticipants(participants);
    final sum = participants.fold(0, (value, item) => value + item.exactMinor);
    if (sum != total || participants.any((item) => item.exactMinor < 0)) {
      throw SplitException(
        SplitFailure.exactMismatch,
        detail: '$sum != $total',
      );
    }
    return SplitResult(
      amountMinor: total,
      subtotalMinor: total,
      shares: [
        for (final participant in participants)
          ExpenseShare(
            userId: participant.userId,
            amountMinor: participant.exactMinor,
            subtotalMinor: participant.exactMinor,
          ),
      ],
    );
  }

  static SplitResult _itemized({
    required int totalMinor,
    required List<SplitParticipant> participants,
    required List<ExpenseItem> items,
    required int taxMinor,
    required int serviceMinor,
    required int discountMinor,
  }) {
    if (items.isEmpty) {
      throw const SplitException(SplitFailure.noItems);
    }

    for (final item in items) {
      if (item.totalMinor < 0) {
        throw SplitException(SplitFailure.invalidItem, detail: item.name);
      }
      if (item.memberIds.isEmpty) {
        throw SplitException(SplitFailure.itemWithoutOwner, detail: item.name);
      }
    }

    final order = <String>[];
    final subtotalByUser = <String, int>{};
    final itemIdsByUser = <String, List<String>>{};
    final participantOrder = participants.map((p) => p.userId).toList();

    void remember(String userId) {
      if (!order.contains(userId)) order.add(userId);
    }

    for (final user in participantOrder) {
      remember(user);
    }

    for (final item in items) {
      final assignees = item.memberIds.toSet().toList(growable: false);
      for (final userId in assignees) {
        remember(userId);
      }
      final shares = allocate(
        item.totalMinor,
        List<int>.filled(assignees.length, 1),
      );
      for (var i = 0; i < assignees.length; i++) {
        final userId = assignees[i];
        subtotalByUser[userId] = (subtotalByUser[userId] ?? 0) + shares[i];
        final ids = itemIdsByUser.putIfAbsent(userId, () => []);
        ids.add(item.id);
      }
    }

    final subtotal = subtotalByUser.values.fold(
      0,
      (value, item) => value + item,
    );
    if (subtotal <= 0) {
      throw const SplitException(SplitFailure.noItems);
    }

    final itemWeights = [for (final user in order) subtotalByUser[user] ?? 0];
    final taxShares = allocate(taxMinor, itemWeights);
    final serviceShares = allocate(serviceMinor, itemWeights);
    final discountShares = allocate(discountMinor, itemWeights);

    final afterOverhead = subtotal + taxMinor + serviceMinor - discountMinor;
    final adjustment = totalMinor - afterOverhead;
    final adjustmentWeights = <int>[
      for (var i = 0; i < order.length; i++)
        (subtotalByUser[order[i]] ?? 0) +
            taxShares[i] +
            serviceShares[i] -
            discountShares[i],
    ];
    final adjustmentShares = allocate(
      adjustment.abs(),
      adjustmentWeights.any((weight) => weight > 0)
          ? adjustmentWeights
          : List<int>.filled(order.length, 1),
    );

    final shares = <ExpenseShare>[];
    for (var i = 0; i < order.length; i++) {
      final userId = order[i];
      final subtotalShare = subtotalByUser[userId] ?? 0;
      final adjustmentShare = adjustment >= 0
          ? adjustmentShares[i]
          : -adjustmentShares[i];
      final amount =
          subtotalShare +
          taxShares[i] +
          serviceShares[i] -
          discountShares[i] +
          adjustmentShare;
      if (amount < 0) {
        throw const SplitException(SplitFailure.invalidItem);
      }
      shares.add(
        ExpenseShare(
          userId: userId,
          amountMinor: amount,
          subtotalMinor: subtotalShare,
          taxShareMinor: taxShares[i],
          serviceShareMinor: serviceShares[i],
          discountShareMinor: discountShares[i],
          adjustmentMinor: adjustmentShare,
          weightBps: subtotal == 0 ? 0 : (subtotalShare * 10000) ~/ subtotal,
          itemIds: itemIdsByUser[userId] ?? const [],
        ),
      );
    }

    return SplitResult(
      shares: shares,
      amountMinor: totalMinor,
      subtotalMinor: subtotal,
      taxMinor: taxMinor,
      serviceMinor: serviceMinor,
      discountMinor: discountMinor,
      adjustmentMinor: adjustment,
    );
  }

  static void _requireParticipants(List<SplitParticipant> participants) {
    if (participants.isEmpty) {
      throw const SplitException(SplitFailure.emptyParticipants);
    }
    if (participants.map((item) => item.userId).toSet().length !=
        participants.length) {
      throw const SplitException(SplitFailure.emptyParticipants);
    }
  }

  /// Splits [total] across [weights] so the result sums exactly to [total].
  ///
  /// Uses the largest-remainder method. Ties are resolved by input order so
  /// the same expense always produces the same shares on every device.
  static List<int> allocate(int total, List<int> weights) {
    if (weights.isEmpty) return const [];
    if (total == 0) return List<int>.filled(weights.length, 0);
    final clean = weights.map((weight) => weight < 0 ? 0 : weight).toList();
    var sum = clean.fold(0, (value, weight) => value + weight);
    if (sum <= 0) {
      for (var i = 0; i < clean.length; i++) {
        clean[i] = 1;
      }
      sum = clean.length;
    }

    final amounts = List<int>.filled(clean.length, 0);
    final remainders = List<int>.filled(clean.length, 0);
    var allocated = 0;
    for (var i = 0; i < clean.length; i++) {
      final product = total * clean[i];
      amounts[i] = product ~/ sum;
      remainders[i] = product % sum;
      allocated += amounts[i];
    }

    var leftover = total - allocated;
    final order = List<int>.generate(clean.length, (index) => index)
      ..sort((a, b) {
        final byRemainder = remainders[b].compareTo(remainders[a]);
        return byRemainder != 0 ? byRemainder : a.compareTo(b);
      });
    for (var i = 0; i < leftover; i++) {
      amounts[order[i % order.length]] += 1;
    }
    return amounts;
  }
}
