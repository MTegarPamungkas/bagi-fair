import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/data/repositories/notification_repository_impl.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStore extends Mock implements LocalStore {}

class _MockQueue extends Mock implements MutationQueue {}

void main() {
  late _MockStore store;
  late _MockQueue queue;
  late NotificationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(OutboxOperation.upsert);
  });

  setUp(() {
    store = _MockStore();
    queue = _MockQueue();
    repository = NotificationRepositoryImpl(store, queue);

    when(() => queue.isDemo).thenReturn(false);
    when(
      () => store.put(any(), any(), pending: any(named: 'pending')),
    ).thenAnswer((_) async {});
    when(
      () => queue.enqueue(
        table: any(named: 'table'),
        rowId: any(named: 'rowId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  AppNotification notification({DateTime? readAt}) => AppNotification(
    id: 'notification-1',
    userId: 'user-me',
    groupId: 'group-1',
    actorId: 'user-friend',
    actorName: 'Sinta',
    kind: AppNotificationKind.nudge,
    title: 'Colek halus',
    body: 'Cek patungan villa ya.',
    createdAt: DateTime.utc(2026, 10, 27, 7),
    readAt: readAt,
  );

  test('marking a received notification read queues a patch, not an upsert', () async {
    await repository.markRead(notification());

    final captured = verify(
      () => queue.enqueue(
        table: 'notifications',
        rowId: 'notification-1',
        operation: captureAny(named: 'operation'),
        payload: captureAny(named: 'payload'),
      ),
    ).captured;

    expect(captured[0], OutboxOperation.patch);
    final payload = captured[1] as Map<String, dynamic>;
    expect(payload.keys, ['read_at']);
    expect(payload['read_at'], isA<String>());
  });
  test('already-read notifications are ignored', () async {
    await repository.markRead(notification(readAt: DateTime.utc(2026, 10, 27)));

    verifyNever(
      () => queue.enqueue(
        table: any(named: 'table'),
        rowId: any(named: 'rowId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('outbound notifications use a plain insert, not an upsert', () async {
    await repository.send(notification());

    verify(
      () => queue.enqueue(
        table: 'notifications',
        rowId: 'notification-1',
        operation: OutboxOperation.insert,
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });
}
