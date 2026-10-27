import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The Bagi Fair mark: one circle cut into three equal wedges.
///
/// Deliberately painted instead of using an icon font so the identity is not
/// tied to a stock Material glyph (a wallet or a coin). The equal cuts are the
/// product promise: nothing is left over, nobody gets a bigger slice.
class FairLogo extends StatelessWidget {
  const FairLogo({super.key, this.size = 44, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SplitMarkPainter(
          first: fair.accent,
          second: fair.tang,
          third: fair.blue,
          ink: fair.ink,
          background: fair.surface,
        ),
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.appName,
              style: AppTypography.heading(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w800,
                color: fair.ink,
                letterSpacing: -0.6,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.taglineShort,
              style: context.texts.labelSmall?.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.4,
                color: fair.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SplitMarkPainter extends CustomPainter {
  const _SplitMarkPainter({
    required this.first,
    required this.second,
    required this.third,
    required this.ink,
    required this.background,
  });

  final Color first;
  final Color second;
  final Color third;
  final Color ink;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final gap = size.width * 0.035;

    final wedges = <(double, Color)>[
      (-90, first),
      (30, second),
      (150, third),
    ];

    final plate = Paint()..color = ink;
    canvas.drawCircle(center, radius, plate);

    for (final (startDegrees, color) in wedges) {
      final start = (startDegrees * 3.141592653589793) / 180;
      final sweep = (120 * 3.141592653589793) / 180;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius - gap),
          start + 0.035,
          sweep - 0.07,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // A small paper-coloured dot in the middle: the shared table.
    canvas.drawCircle(center, size.width * 0.075, Paint()..color = background);
    canvas.drawCircle(
      center,
      size.width * 0.075,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02,
    );
  }

  @override
  bool shouldRepaint(_SplitMarkPainter oldDelegate) =>
      oldDelegate.first != first ||
      oldDelegate.second != second ||
      oldDelegate.third != third ||
      oldDelegate.ink != ink ||
      oldDelegate.background != background;
}
