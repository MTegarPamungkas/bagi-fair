import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:flutter/material.dart';

class SettlementDraft {
  const SettlementDraft({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.note,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String note;
}

Future<SettlementDraft?> showSettleSheet(
  BuildContext context, {
  required String currency,
  required List<GroupMember> members,
  required String currentUserId,
  String? fromUserId,
  String? toUserId,
  int? amountMinor,
}) {
  return showModalBottomSheet<SettlementDraft>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettleSheet(
      currency: currency,
      members: members,
      currentUserId: currentUserId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amountMinor: amountMinor,
    ),
  );
}

class _SettleSheet extends StatefulWidget {
  const _SettleSheet({
    required this.currency,
    required this.members,
    required this.currentUserId,
    this.fromUserId,
    this.toUserId,
    this.amountMinor,
  });

  final String currency;
  final List<GroupMember> members;
  final String currentUserId;
  final String? fromUserId;
  final String? toUserId;
  final int? amountMinor;

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late final TextEditingController _amount = TextEditingController(
    text: widget.amountMinor == null
        ? ''
        : MoneyFormatter.input(widget.amountMinor!, currency: widget.currency),
  );
  late String _from = widget.fromUserId ?? widget.currentUserId;
  late String _to =
      widget.toUserId ??
      (widget.members
              .where((member) => member.userId != widget.currentUserId)
              .isEmpty
          ? widget.currentUserId
          : widget.members
                .firstWhere((member) => member.userId != widget.currentUserId)
                .userId);
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale.languageCode;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: l10n.settleTitle,
                subtitle: l10n.settleSubtitle,
                icon: Icons.handshake_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              _memberDropdown(
                label: l10n.settleWith,
                value: _from,
                onChanged: (value) => setState(() => _from = value!),
              ),
              const SizedBox(height: AppSpacing.xs),
              _memberDropdown(
                label: l10n.paidBy,
                value: _to,
                onChanged: (value) => setState(() => _to = value!),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.settlementAmount,
                  prefixText: '${MoneyFormatter.symbolFor(widget.currency)} ',
                  errorText: _error,
                ),
                validator: (value) {
                  final minor = MoneyFormatter.parse(
                    value ?? '',
                    currency: widget.currency,
                  );
                  if (minor == null || minor <= 0) {
                    return l10n.amountRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: l10n.settlementNote,
                  hintText: l10n.settlementNoteHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _submit(context),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l10n.markSettled),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.settlementFromTo} · ${MoneyFormatter.format(widget.amountMinor ?? 0, currency: widget.currency, localeCode: locale)}',
                textAlign: TextAlign.center,
                style: context.texts.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: widget.members.any((member) => member.userId == value)
          ? value
          : (widget.members.isEmpty ? null : widget.members.first.userId),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final member in widget.members)
          DropdownMenuItem(
            value: member.userId,
            child: Row(
              children: [
                AvatarCircle(name: member.displayName, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.userId == widget.currentUserId
                        ? '${member.displayName} (${context.l10n.you})'
                        : member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_from == _to) {
      setState(() => _error = context.l10n.participantRequired);
      return;
    }
    final minor = MoneyFormatter.parse(_amount.text, currency: widget.currency);
    if (minor == null || minor <= 0) {
      setState(() => _error = context.l10n.amountRequired);
      return;
    }
    Navigator.of(context).pop(
      SettlementDraft(
        fromUserId: _from,
        toUserId: _to,
        amountMinor: minor,
        note: _note.text.trim(),
      ),
    );
  }
}
