import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The shared paper canvas behind every screen.
///
/// It fills the available space (so short pages never leak a black band behind
/// the content) and prints a faint dot grid, like a receipt pad.
class FairBackground extends StatelessWidget {
  const FairBackground({
    super.key,
    required this.child,
    this.padding,
    this.showGrid = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return ColoredBox(
      color: fair.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showGrid)
            IgnorePointer(
              child: CustomPaint(painter: _PaperGridPainter(color: fair.line)),
            ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

class _PaperGridPainter extends CustomPainter {
  const _PaperGridPainter({required this.color});

  final Color color;

  static const double _step = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (var y = _step / 2; y < size.height; y += _step) {
      for (var x = _step / 2; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), 0.85, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PaperGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
