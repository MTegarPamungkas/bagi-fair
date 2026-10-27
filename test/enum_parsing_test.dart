import 'package:bagi_fair/core/utils/enum_parsing.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity kinds parse snake_case from SQL RPCs and camelCase cache', () {
    expect(
      parseEnum(ActivityKind.values, 'member_joined', ActivityKind.groupUpdated),
      ActivityKind.memberJoined,
    );
    expect(
      parseEnum(ActivityKind.values, 'expenseAdded', ActivityKind.groupUpdated),
      ActivityKind.expenseAdded,
    );
    expect(
      parseEnum(
        ActivityKind.values,
        'settlement_added',
        ActivityKind.groupUpdated,
      ),
      ActivityKind.settlementAdded,
    );
  });

  test('unknown activity kinds fall back instead of throwing', () {
    expect(
      parseEnum(ActivityKind.values, 'mystery', ActivityKind.groupUpdated),
      ActivityKind.groupUpdated,
    );
    expect(
      parseEnum(ActivityKind.values, null, ActivityKind.groupUpdated),
      ActivityKind.groupUpdated,
    );
  });

  test('notification kinds parse both shapes', () {
    expect(
      parseEnum(
        AppNotificationKind.values,
        'expense_added',
        AppNotificationKind.reminder,
      ),
      AppNotificationKind.expenseAdded,
    );
    expect(
      parseEnum(AppNotificationKind.values, 'nudge', AppNotificationKind.reminder),
      AppNotificationKind.nudge,
    );
  });

  test('enums are written back as snake_case', () {
    expect(enumToSnake(ActivityKind.memberJoined), 'member_joined');
    expect(enumToSnake(ActivityKind.nudgeSent), 'nudge_sent');
    expect(enumToSnake(AppNotificationKind.settlementAdded), 'settlement_added');
    expect(enumToSnake(AppNotificationKind.nudge), 'nudge');
  });

  test('activity round-trips through JSON', () {
    final entry = ActivityEntry(
      id: 'a1',
      groupId: 'g1',
      actorId: 'u1',
      actorName: 'Budi',
      kind: ActivityKind.memberJoined,
      summary: 'bergabung',
      createdAt: DateTime.utc(2026, 10, 27),
    );
    final restored = ActivityEntry.fromJson(entry.toJson());
    expect(restored.kind, ActivityKind.memberJoined);
    expect(restored.actorName, 'Budi');
  });
}
