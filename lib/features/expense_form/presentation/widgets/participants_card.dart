import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParticipantsCard extends StatelessWidget {
  const ParticipantsCard({
    super.key,
    required this.state,
    required this.currentUserId,
  });

  final ExpenseFormState state;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ExpenseFormBloc>();
    final selected = state.participantIds.toSet();
    return FairCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.participants.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
                ),
              ),
              TextButton(
                onPressed: () =>
                    bloc.add(const ExpenseFormAllParticipantsSelected()),
                child: Text(l10n.selectAll),
              ),
              TextButton(
                onPressed: () {
                  for (final id in [...state.participantIds].skip(1)) {
                    bloc.add(ExpenseFormParticipantToggled(id));
                  }
                },
                child: Text(l10n.clearAll),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final member in state.members)
                MemberChip(
                  member: member,
                  selected: selected.contains(member.userId),
                  isYou: member.userId == currentUserId,
                  onTap: () =>
                      bloc.add(ExpenseFormParticipantToggled(member.userId)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    required this.selected,
    required this.isYou,
    required this.onTap,
  });

  final GroupMember member;
  final bool selected;
  final bool isYou;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: fair.surface,
      selectedColor: fair.accentSoft,
      side: BorderSide(color: selected ? fair.accent : fair.line),
      avatar: AvatarCircle(
        name: member.displayName,
        imageUrl: member.avatarUrl,
        size: 24,
      ),
      label: Text(
        isYou
            ? '${member.displayName} (${context.l10n.you})'
            : member.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      showCheckmark: false,
    );
  }
}
