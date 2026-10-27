import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

/// A small tinted tile that encodes the group type with colour + glyph.
class GroupTypeIcon extends StatelessWidget {
  const GroupTypeIcon({super.key, required this.type, this.size = 44});

  final GroupType type;
  final double size;

  static IconData iconFor(GroupType type) => switch (type) {
    GroupType.trip => Icons.flight_takeoff_rounded,
    GroupType.kos => Icons.home_work_rounded,
    GroupType.hangout => Icons.local_cafe_rounded,
    GroupType.other => Icons.groups_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = switch (type) {
      GroupType.trip => fair.blue,
      GroupType.kos => fair.accent,
      GroupType.hangout => fair.tang,
      GroupType.other => fair.inkMuted,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(iconFor(type), size: size * 0.46, color: color),
    );
  }
}
