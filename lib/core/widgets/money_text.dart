import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';

/// All money is rendered in a tabular monospace face so columns line up and
/// digits do not jiggle when a value changes.
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.minor,
    required this.currency,
    this.localeCode = 'id',
    this.style,
    this.signed = false,
    this.compact = false,
    this.color,
    this.fit = false,
    this.align = TextAlign.start,
    this.maxLines = 1,
  });

  final int minor;
  final String currency;
  final String localeCode;
  final TextStyle? style;
  final bool signed;
  final bool compact;
  final Color? color;
  final bool fit;
  final TextAlign align;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      MoneyFormatter.format(
        minor,
        currency: currency,
        localeCode: localeCode,
        signed: signed,
        compact: compact,
      ),
      textAlign: align,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.money(
        fontSize: style?.fontSize,
        fontWeight: style?.fontWeight ?? FontWeight.w600,
        color: color ?? style?.color ?? context.fair.ink,
        height: style?.height,
        letterSpacing: style?.letterSpacing ?? -0.4,
      ),
    );
    if (!fit) return text;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: text,
    );
  }
}

/// The "why is this number this size?" building block: label on the left,
/// amount on the right, perfectly aligned.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.minor,
    required this.currency,
    this.localeCode = 'id',
    this.muted = false,
    this.emphasis = false,
    this.color,
    this.icon,
    this.trailingLabel,
  });

  final String label;
  final int minor;
  final String currency;
  final String localeCode;
  final bool muted;
  final bool emphasis;
  final Color? color;
  final IconData? icon;
  final Widget? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fair.inkMuted),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: emphasis
                        ? context.texts.titleSmall
                        : context.texts.bodySmall?.copyWith(
                            color: muted ? fair.inkMuted : fair.ink,
                          ),
                  ),
                ),
                if (trailingLabel != null) ...[
                  const SizedBox(width: 6),
                  trailingLabel!,
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AmountText(
            minor: minor,
            currency: currency,
            localeCode: localeCode,
            color: color ?? (muted ? fair.inkMuted : fair.ink),
            style: emphasis
                ? context.texts.titleSmall
                : context.texts.bodyMedium,
          ),
        ],
      ),
    );
  }
}
