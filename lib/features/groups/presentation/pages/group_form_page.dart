import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/group_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupFormPage extends StatelessWidget {
  const GroupFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupFormBloc>(),
      child: const _GroupFormView(),
    );
  }
}

class _GroupFormView extends StatefulWidget {
  const _GroupFormView();

  @override
  State<_GroupFormView> createState() => _GroupFormViewState();
}

class _GroupFormViewState extends State<_GroupFormView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  GroupType _type = GroupType.trip;
  String _emoji = '🏝️';
  String _currency = 'IDR';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = context.screenWidth > 940
        ? (context.screenWidth - 860) / 2
        : context.pagePadding;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.newGroup),
      ),
      body: FairBackground(
        child: BlocConsumer<GroupFormBloc, GroupFormState>(
          listenWhen: (previous, current) =>
              previous.errorCode != current.errorCode ||
              previous.createdGroupId != current.createdGroupId,
          listener: (context, state) {
            if (state.errorCode != null) {
              showFairSnack(context, _error(context, state.errorCode!));
            }
            if (state.createdGroupId != null) {
              showFairSnack(context, l10n.groupCreated);
              context.pushReplacement('/groups/${state.createdGroupId}');
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  12,
                  horizontal,
                  120,
                ),
                children: [
                  PageHeader(
                    eyebrow: l10n.groups,
                    title: l10n.newGroup,
                    subtitle: l10n.groupsSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FairCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.groupEmoji.toUpperCase(),
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final emoji in groupEmojiChoices)
                              _EmojiChoice(
                                emoji: emoji,
                                selected: emoji == _emoji,
                                onTap: () => setState(() => _emoji = emoji),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.groupName,
                            hintText: l10n.groupNameHint,
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? l10n.nameRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _description,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.groupDescription,
                            hintText: l10n.groupDescriptionHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FairCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.groupType.toUpperCase(),
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final type in GroupType.values)
                              Pill(
                                label: l10n.groupTypeName(type),
                                icon: GroupTypeIcon.iconFor(type),
                                selected: _type == type,
                                onTap: () => setState(() {
                                  _type = type;
                                  _emoji = emojiForGroupType(type);
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        InkWell(
                          borderRadius: AppRadius.allMd,
                          onTap: () async {
                            final currency = await showCurrencyPicker(
                              context,
                              selected: _currency,
                            );
                            if (currency != null) {
                              setState(() => _currency = currency);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.groupCurrency,
                              suffixIcon: const Icon(Icons.expand_more_rounded),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  MoneyFormatter.symbolFor(_currency),
                                  style: context.texts.titleMedium,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$_currency · ${MoneyFormatter.names[_currency] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.texts.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.membersCount(1),
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: state.submitting
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              context.read<GroupFormBloc>().add(
                                GroupFormSubmitted(
                                  name: _name.text,
                                  description: _description.text,
                                  emoji: _emoji,
                                  type: _type,
                                  currency: _currency,
                                ),
                              );
                            }
                          },
                    icon: state.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.createGroup),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'name_required' => l10n.nameRequired,
      'not_signed_in' => l10n.signIn,
      _ => l10n.saveFailed,
    };
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? fair.accentSoft : fair.surfaceMuted,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: selected ? fair.accent : fair.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
