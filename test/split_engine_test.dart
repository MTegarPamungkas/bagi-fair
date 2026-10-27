import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/usecases/split_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('equal split', () {
    test('splits odd amounts without losing a single unit', () {
      final result = SplitEngine.compute(
        totalMinor: 100000,
        mode: SplitMode.equal,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
          SplitParticipant(userId: 'c'),
        ],
      );

      expect(result.shares.map((share) => share.amountMinor), [
        33334,
        33333,
        33333,
      ]);
      expect(
        result.shares.fold(0, (sum, share) => sum + share.amountMinor),
        100000,
      );
    });

    test('is deterministic for the same input', () {
      final first = SplitEngine.compute(
        totalMinor: 1001,
        mode: SplitMode.equal,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
        ],
      );
      final second = SplitEngine.compute(
        totalMinor: 1001,
        mode: SplitMode.equal,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
        ],
      );
      expect(
        first.shares.map((share) => share.amountMinor),
        second.shares.map((share) => share.amountMinor),
      );
    });
  });

  group('percentage split', () {
    test('allocates exactly by basis points', () {
      final result = SplitEngine.compute(
        totalMinor: 100000,
        mode: SplitMode.percentage,
        participants: const [
          SplitParticipant(userId: 'a', weightBps: 5000),
          SplitParticipant(userId: 'b', weightBps: 3000),
          SplitParticipant(userId: 'c', weightBps: 2000),
        ],
      );
      expect(result.shares.map((share) => share.amountMinor), [
        50000,
        30000,
        20000,
      ]);
    });

    test('handles repeating percentages with largest remainder', () {
      final result = SplitEngine.compute(
        totalMinor: 1000,
        mode: SplitMode.percentage,
        participants: const [
          SplitParticipant(userId: 'a', weightBps: 3333),
          SplitParticipant(userId: 'b', weightBps: 3333),
          SplitParticipant(userId: 'c', weightBps: 3334),
        ],
      );
      expect(result.shares.map((share) => share.amountMinor), [333, 333, 334]);
      expect(
        result.shares.fold(0, (sum, share) => sum + share.amountMinor),
        1000,
      );
    });

    test('rejects percentages that do not add up to 100%', () {
      expect(
        () => SplitEngine.compute(
          totalMinor: 1000,
          mode: SplitMode.percentage,
          participants: const [
            SplitParticipant(userId: 'a', weightBps: 5000),
            SplitParticipant(userId: 'b', weightBps: 4000),
          ],
        ),
        throwsA(
          isA<SplitException>().having(
            (error) => error.failure,
            'failure',
            SplitFailure.percentageNotHundred,
          ),
        ),
      );
    });
  });

  group('exact split', () {
    test('keeps custom amounts when they match the total', () {
      final result = SplitEngine.compute(
        totalMinor: 90000,
        mode: SplitMode.exact,
        participants: const [
          SplitParticipant(userId: 'a', exactMinor: 60000),
          SplitParticipant(userId: 'b', exactMinor: 30000),
        ],
      );
      expect(result.shares.map((share) => share.amountMinor), [60000, 30000]);
    });

    test('rejects custom amounts that do not match the total', () {
      expect(
        () => SplitEngine.compute(
          totalMinor: 90000,
          mode: SplitMode.exact,
          participants: const [
            SplitParticipant(userId: 'a', exactMinor: 60000),
            SplitParticipant(userId: 'b', exactMinor: 20000),
          ],
        ),
        throwsA(isA<SplitException>()),
      );
    });
  });

  group('itemized split', () {
    const items = [
      ExpenseItem(
        id: 'i1',
        name: 'Nasi goreng',
        unitPriceMinor: 60000,
        totalMinor: 60000,
        memberIds: ['a'],
      ),
      ExpenseItem(
        id: 'i2',
        name: 'Es teh',
        unitPriceMinor: 40000,
        totalMinor: 40000,
        memberIds: ['b'],
      ),
    ];

    test('distributes tax and service proportional to items', () {
      final result = SplitEngine.compute(
        totalMinor: 120000,
        mode: SplitMode.itemized,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
        ],
        items: items,
        taxMinor: 10000,
        serviceMinor: 10000,
      );

      final a = result.shares.firstWhere((share) => share.userId == 'a');
      final b = result.shares.firstWhere((share) => share.userId == 'b');
      expect(a.subtotalMinor, 60000);
      expect(b.subtotalMinor, 40000);
      expect(a.taxShareMinor + a.serviceShareMinor, 12000);
      expect(b.taxShareMinor + b.serviceShareMinor, 8000);
      expect(a.amountMinor, 72000);
      expect(b.amountMinor, 48000);
      expect(result.adjustmentMinor, 0);
    });

    test('splits a shared item equally between assignees', () {
      final result = SplitEngine.compute(
        totalMinor: 100000,
        mode: SplitMode.itemized,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
        ],
        items: const [
          ExpenseItem(
            id: 'pizza',
            name: 'Pizza besar',
            unitPriceMinor: 100000,
            totalMinor: 100000,
            memberIds: ['a', 'b'],
          ),
        ],
      );
      expect(result.shares.map((share) => share.amountMinor), [50000, 50000]);
    });

    test('absorbs receipt rounding differences in the adjustment line', () {
      final result = SplitEngine.compute(
        totalMinor: 120001,
        mode: SplitMode.itemized,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
        ],
        items: items,
        taxMinor: 10000,
        serviceMinor: 10000,
      );
      expect(result.adjustmentMinor, 1);
      expect(
        result.shares.fold(0, (sum, share) => sum + share.amountMinor),
        120001,
      );
    });

    test('requires every item to have an owner', () {
      expect(
        () => SplitEngine.compute(
          totalMinor: 60000,
          mode: SplitMode.itemized,
          participants: const [SplitParticipant(userId: 'a')],
          items: const [
            ExpenseItem(
              id: 'i1',
              name: 'Tanpa pemilik',
              unitPriceMinor: 60000,
              totalMinor: 60000,
            ),
          ],
        ),
        throwsA(
          isA<SplitException>().having(
            (error) => error.failure,
            'failure',
            SplitFailure.itemWithoutOwner,
          ),
        ),
      );
    });

    test('handles odd tax units without drifting', () {
      final result = SplitEngine.compute(
        totalMinor: 100001,
        mode: SplitMode.itemized,
        participants: const [
          SplitParticipant(userId: 'a'),
          SplitParticipant(userId: 'b'),
          SplitParticipant(userId: 'c'),
        ],
        items: const [
          ExpenseItem(
            id: 'i1',
            name: 'A',
            unitPriceMinor: 33333,
            totalMinor: 33333,
            memberIds: ['a'],
          ),
          ExpenseItem(
            id: 'i2',
            name: 'B',
            unitPriceMinor: 33333,
            totalMinor: 33333,
            memberIds: ['b'],
          ),
          ExpenseItem(
            id: 'i3',
            name: 'C',
            unitPriceMinor: 33334,
            totalMinor: 33334,
            memberIds: ['c'],
          ),
        ],
        taxMinor: 1,
      );
      expect(
        result.shares.fold(0, (sum, share) => sum + share.amountMinor),
        100001,
      );
    });
  });
}
