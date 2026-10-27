import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 38,
    this.highlight = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool highlight;

  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1
        ? parts.last.substring(0, 1).toUpperCase()
        : '';
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final palette = [fair.accent, fair.tang, fair.blue, fair.negative];
    final color =
        palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? fair.accent : color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlight ? fair.accent : color.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Text(
        initialsFor(name),
        style: context.texts.labelSmall?.copyWith(
          color: highlight ? fair.onAccent : color,
          fontFamily: AppTypography.mono,
          fontSize: size * 0.29,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.size = 30,
    this.max = 4,
    this.extraLabel,
  });

  final List<String> names;
  final double size;
  final int max;
  final String? extraLabel;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(max).toList(growable: false);
    final extra = names.length - visible.length;
    final fair = context.fair;
    return SizedBox(
      height: size,
      width: visible.length * size * 0.7 + (extra > 0 ? size * 0.7 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * size * 0.7,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: fair.surface,
                  shape: BoxShape.circle,
                ),
                child: AvatarCircle(name: visible[i], size: size - 3),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * size * 0.7,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fair.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: fair.line),
                ),
                child: Text(
                  '+$extra',
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: size * 0.3,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
