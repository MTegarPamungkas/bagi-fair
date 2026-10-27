import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/bloc/receipt_scan_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step 2: every AI value is an editable field. Nothing is saved until the user
/// has seen and corrected it.
class ScanReviewStage extends StatelessWidget {
  const ScanReviewStage({
    super.key,
    required this.state,
    required this.merchant,
    required this.tax,
    required this.service,
    required this.onPickAgain,
    required this.onEvent,
  });

  final ReceiptScanState state;
  final TextEditingController merchant;
  final TextEditingController tax;
  final TextEditingController service;
  final VoidCallback onPickAgain;
  final ValueChanged<ReceiptScanEvent> onEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.scanning) ...[
          FairCard(
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scanningReceipt,
                        style: context.texts.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t(
                          'AI membaca item, pajak, dan total.',
                          'AI is reading items, tax, and total.',
                        ),
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.scanErrorCode != null) ...[
          FairCard(
            tone: fair.warningSoft,
            borderColor: fair.warning.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 17,
                      color: fair.warning,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l10n.scanFailed,
                        style: context.texts.titleSmall?.copyWith(
                          color: fair.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(switch (state.scanErrorCode) {
                  'rate_limited' => l10n.rateLimitBody,
                  'ai_not_configured' => l10n.aiNotConfigured,
                  'cloud_unavailable' => l10n.aiNeedsCloud,
                  _ => l10n.scanFailedBody,
                }, style: context.texts.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPickAgain,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.retry),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          onEvent(const ReceiptScanSampleRequested()),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: Text(l10n.scanDemo),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.imageBytes != null) ...[
          FairCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            clip: true,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.allMd,
                  child: Image.memory(
                    state.imageBytes!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.reviewReceipt, style: context.texts.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        state.confidence == null
                            ? l10n.reviewSubtitle
                            : l10n.t(
                                'Keyakinan AI ${MoneyFormatter.percent(state.confidence!, localeCode: l10n.locale.languageCode)}',
                                'AI confidence ${MoneyFormatter.percent(state.confidence!, localeCode: l10n.locale.languageCode)}',
                              ),
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.choosePhoto,
                  onPressed: onPickAgain,
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FairCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.merchant, style: context.texts.titleSmall),
                  ),
                  Pill(
                    label: l10n.aiPowered,
                    icon: Icons.auto_awesome_rounded,
                    tone: fair.blue,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: merchant,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) =>
                    onEvent(ReceiptScanMerchantChanged(value)),
                decoration: InputDecoration(
                  hintText: l10n.t('Nama warung / toko', 'Shop name'),
                  prefixIcon: const Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      date: state.effectiveDate,
                      onTap: () async {
                        final picked = await showFairDatePicker(
                          context,
                          initial: state.effectiveDate,
                        );
                        if (picked != null) {
                          onEvent(ReceiptScanDateChanged(picked));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: InkWell(
                      borderRadius: AppRadius.allMd,
                      onTap: () async {
                        final picked = await showCurrencyPicker(
                          context,
                          selected: state.currency,
                        );
                        if (picked != null) {
                          onEvent(ReceiptScanCurrencyChanged(picked));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: fair.surfaceMuted,
                          borderRadius: AppRadius.allMd,
                          border: Border.all(color: fair.line),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 17,
                              color: fair.inkMuted,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                state.currency,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.titleSmall,
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 17,
                              color: fair.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FairCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: l10n.receiptItems,
                subtitle: l10n.t(
                  'Ketuk harga untuk mengubah.',
                  'Tap a price to edit.',
                ),
                action: TextButton.icon(
                  onPressed: () => onEvent(const ReceiptScanItemAdded()),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(l10n.add),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    l10n.t(
                      'Belum ada item. Tambahkan manual.',
                      'No items yet. Add them manually.',
                    ),
                    textAlign: TextAlign.center,
                    style: context.texts.bodySmall,
                  ),
                )
              else
                for (final item in state.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ScanItemEditor(
                      key: ValueKey(item.id),
                      item: item,
                      currency: state.currency,
                      onChanged: (next) =>
                          onEvent(ReceiptScanItemUpdated(next)),
                      onRemove: () => onEvent(ReceiptScanItemRemoved(item.id)),
                    ),
                  ),
              const SizedBox(height: AppSpacing.sm),
              Divider(color: fair.line),
              const SizedBox(height: AppSpacing.xs),
              InfoRow(
                label: l10n.itemSubtotal,
                value: MoneyFormatter.format(
                  state.computedSubtotal,
                  currency: state.currency,
                  localeCode: l10n.locale.languageCode,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _MoneyField(
                      controller: tax,
                      label: l10n.tax,
                      currency: state.currency,
                      onChanged: (minor) =>
                          onEvent(ReceiptScanTaxChanged(minor)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MoneyField(
                      controller: service,
                      label: l10n.service,
                      currency: state.currency,
                      onChanged: (minor) =>
                          onEvent(ReceiptScanServiceChanged(minor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: fair.accentSoft,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(
                    color: fair.accent.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.total, style: context.texts.titleSmall),
                    ),
                    AmountText(
                      minor: state.computedTotal,
                      currency: state.currency,
                      localeCode: l10n.locale.languageCode,
                      style: context.texts.headlineSmall?.copyWith(
                        color: fair.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: onPickAgain,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(l10n.choosePhoto),
          ),
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.currency,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String currency;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (value) => onChanged(
        MoneyFormatter.parse(value, currency: currency) ?? 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '${MoneyFormatter.symbolFor(currency)} ',
        isDense: true,
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: fair.surfaceMuted,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: fair.line),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 17, color: fair.inkMuted),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                AppDates.medium(
                  date,
                  localeCode: context.l10n.locale.languageCode,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editable receipt line. Kept compact because a receipt can have 20 of them.
class ScanItemEditor extends StatefulWidget {
  const ScanItemEditor({
    super.key,
    required this.item,
    required this.currency,
    required this.onChanged,
    required this.onRemove,
  });

  final ReceiptItem item;
  final String currency;
  final ValueChanged<ReceiptItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<ScanItemEditor> createState() => _ScanItemEditorState();
}

class _ScanItemEditorState extends State<ScanItemEditor> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _qty = TextEditingController(text: '${widget.item.quantity}');
    _price = TextEditingController(
      text: widget.item.unitPriceMinor > 0
          ? MoneyFormatter.input(
              widget.item.unitPriceMinor,
              currency: widget.currency,
            )
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant ScanItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.name != widget.item.name &&
        _name.text != widget.item.name) {
      _name.text = widget.item.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit({String? name, int? qty, int? unitPrice}) {
    final quantity = qty ?? widget.item.quantity;
    final price = unitPrice ?? widget.item.unitPriceMinor;
    widget.onChanged(
      widget.item.copyWith(
        name: name ?? _name.text,
        quantity: quantity < 1 ? 1 : quantity,
        unitPriceMinor: price < 0 ? 0 : price,
        totalMinor: (quantity < 1 ? 1 : quantity) * (price < 0 ? 0 : price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: fair.surfaceMuted.withValues(alpha: 0.55),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: fair.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) => _emit(name: value),
                  style: context.texts.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.itemName,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 62,
                      child: TextField(
                        controller: _qty,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) =>
                            _emit(qty: int.tryParse(value) ?? 1),
                        style: context.texts.bodySmall,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixText: '× ',
                          hintText: l10n.quantity,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (value) => _emit(
                          unitPrice:
                              MoneyFormatter.parse(
                                value,
                                currency: widget.currency,
                              ) ??
                              (int.tryParse(value) ?? 0),
                        ),
                        style: context.texts.bodySmall,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixText:
                              '${MoneyFormatter.symbolFor(widget.currency)} ',
                          hintText: l10n.itemPrice,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            children: [
              IconButton(
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onRemove,
                icon: Icon(Icons.close_rounded, size: 17, color: fair.inkMuted),
              ),
              Text(
                MoneyFormatter.format(
                  widget.item.totalMinor,
                  currency: widget.currency,
                  localeCode: l10n.locale.languageCode,
                  compact: true,
                ),
                style: context.texts.labelSmall?.copyWith(
                  color: fair.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
