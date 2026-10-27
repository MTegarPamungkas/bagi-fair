import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A sheet of paper: flat surface, ink outline, and a hard offset shadow.
///
/// The hard shadow is intentional. Soft glowing cards read as a generic
/// finance dashboard; a crisp printed edge reads as a receipt on a table.
class FairCard extends StatelessWidget {
  const FairCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.tone,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.gradient,
    this.clip = false,
    this.elevated = true,
    this.borderWidth = 1.2,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tone;
  final Color? borderColor;
  final Radius radius;
  final Gradient? gradient;
  final bool clip;
  final bool elevated;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final background = tone ?? fair.surface;
    final rounded = BorderRadius.all(radius);
    final content = Ink(
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: rounded,
        border: Border.all(
          color: borderColor ?? fair.line,
          width: borderWidth,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: rounded,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: fair.shadow,
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: rounded,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: onTap == null
            ? content
            : InkWell(borderRadius: rounded, onTap: onTap, child: content),
      ),
    );
  }
}

/// A dashed rule with a cut-out notch on both ends, like the perforation on a
/// receipt. Used between ledger sections instead of a full divider.
class PerforatedDivider extends StatelessWidget {
  const PerforatedDivider({
    super.key,
    this.color,
    this.height = 22,
    this.label,
  });

  final Color? color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final line = color ?? fair.line;
    if (label == null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter(color: line)),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(child: CustomPaint(painter: _DashedLinePainter(color: line))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label!.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.4,
                color: fair.inkMuted,
              ),
            ),
          ),
          Expanded(child: CustomPaint(painter: _DashedLinePainter(color: line))),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    const dash = 4.0;
    const gap = 5.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
