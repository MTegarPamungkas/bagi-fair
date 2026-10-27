import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:flutter/material.dart';

/// A vertical ledger timeline: dot, dashed thread, entry.
class GroupActivityTab extends StatelessWidget {
  const GroupActivityTab({super.key, required this.state});

  final GroupDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.activities.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EmptyState(
            icon: Icons.history_rounded,
            title: l10n.noActivity,
            body: l10n.activitySubtitle,
          ),
        ],
      );
    }
    final items = [...state.activities]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final locale = l10n.locale.languageCode;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        AppSpacing.md,
        context.pagePadding,
        120,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final activity = items[index];
        final (icon, tone) = _style(activity.kind, context);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tone.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(icon, size: 13, color: tone),
                    ),
                    if (index != items.length - 1)
                      Expanded(
                        child: CustomPaint(
                          painter: _ThreadPainter(
                            color: context.fair.line,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activity.actorName} ${activity.summary.isEmpty ? l10n.activityVerb(activity.kind) : activity.summary}',
                        style: context.texts.bodyMedium,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            AppDates.relative(
                              activity.createdAt,
                              localeCode: locale,
                            ),
                            style: context.texts.labelSmall?.copyWith(
                              letterSpacing: 0,
                              fontSize: 9,
                            ),
                          ),
                          if (activity.isPending) ...[
                            const SizedBox(width: 8),
                            Pill(
                              label: l10n.pendingSync,
                              dense: true,
                              tone: context.fair.warning,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _style(ActivityKind kind, BuildContext context) {
    final fair = context.fair;
    return switch (kind) {
      ActivityKind.groupCreated => (Icons.celebration_rounded, fair.accent),
      ActivityKind.groupUpdated => (Icons.tune_rounded, fair.blue),
      ActivityKind.memberJoined => (Icons.person_add_alt_1_rounded, fair.blue),
      ActivityKind.memberRemoved => (
        Icons.person_remove_alt_1_rounded,
        fair.warning,
      ),
      ActivityKind.expenseAdded => (Icons.receipt_long_rounded, fair.accent),
      ActivityKind.expenseUpdated => (Icons.edit_note_rounded, fair.warning),
      ActivityKind.expenseDeleted => (
        Icons.delete_outline_rounded,
        fair.negative,
      ),
      ActivityKind.settlementAdded => (
        Icons.check_circle_outline_rounded,
        fair.positive,
      ),
      ActivityKind.receiptScanned => (
        Icons.document_scanner_outlined,
        fair.info,
      ),
      ActivityKind.nudgeSent => (Icons.waving_hand_outlined, fair.warning),
    };
  }
}

class _ThreadPainter extends CustomPainter {
  const _ThreadPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    const gap = 4.0;
    final x = size.width / 2;
    for (var y = 4.0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dash), paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter oldDelegate) => oldDelegate.color != color;
}
