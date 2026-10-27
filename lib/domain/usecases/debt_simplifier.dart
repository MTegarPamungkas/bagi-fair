import 'package:bagi_fair/domain/entities/balance.dart';

/// Turns net balances into the smallest practical set of bank transfers.
///
/// This is the classic largest-debtor/largest-creditor match: every transfer
/// fully removes at least one person from the list, so the result never needs
/// more than `n - 1` transfers. Finding a provably minimal set is NP-hard; this
/// greedy variant is deterministic, easy to explain, and optimal for the small
/// groups this app targets.
abstract final class DebtSimplifier {
  static List<TransferSuggestion> simplify(List<MemberBalance> balances) {
    final creditors = <_Node>[];
    final debtors = <_Node>[];

    for (final balance in balances) {
      if (balance.netMinor > 0) {
        creditors.add(_Node(balance.userId, balance.netMinor));
      } else if (balance.netMinor < 0) {
        debtors.add(_Node(balance.userId, -balance.netMinor));
      }
    }

    creditors.sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      return byAmount != 0 ? byAmount : a.userId.compareTo(b.userId);
    });
    debtors.sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      return byAmount != 0 ? byAmount : a.userId.compareTo(b.userId);
    });

    final transfers = <TransferSuggestion>[];
    var debtorIndex = 0;
    var creditorIndex = 0;

    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;

      if (amount > 0) {
        transfers.add(
          TransferSuggestion(
            fromUserId: debtor.userId,
            toUserId: creditor.userId,
            amountMinor: amount,
          ),
        );
        debtor.amount -= amount;
        creditor.amount -= amount;
      }

      if (debtor.amount == 0) debtorIndex++;
      if (creditor.amount == 0) creditorIndex++;
    }

    return transfers;
  }
}

class _Node {
  _Node(this.userId, this.amount);

  final String userId;
  int amount;
}
