import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ScanStepper extends StatelessWidget {
  const ScanStepper({super.key, required this.manual});

  final bool manual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      l10n.t('Foto struk', 'Photo'),
      l10n.t('Cek hasil', 'Review'),
      l10n.t('Bagi adil', 'Split'),
    ];
    final active = manual ? 1 : 0;
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: index <= active
                    ? context.fair.accent.withValues(alpha: 0.5)
                    : context.fair.line,
              ),
            ),
          _StepBadge(
            number: index + 1,
            label: steps[index],
            state: index < active
                ? _StepState.done
                : index == active
                ? _StepState.active
                : _StepState.todo,
          ),
        ],
      ],
    );
  }
}

enum _StepState { todo, active, done }

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.label,
    required this.state,
  });

  final int number;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final color = switch (state) {
      _StepState.done => fair.positive,
      _StepState.active => fair.accent,
      _StepState.todo => fair.inkMuted,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: state == _StepState.active
                ? color
                : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: state == _StepState.done
              ? Icon(Icons.check_rounded, size: 15, color: color)
              : Text(
                  '$number',
                  style: context.texts.labelSmall?.copyWith(
                    color: state == _StepState.active ? fair.onAccent : color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.labelSmall?.copyWith(
            fontSize: 9,
            color: state == _StepState.todo ? fair.inkMuted : fair.ink,
          ),
        ),
      ],
    );
  }
}
