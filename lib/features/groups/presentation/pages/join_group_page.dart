import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/features/groups/presentation/bloc/join_group_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class JoinGroupPage extends StatelessWidget {
  const JoinGroupPage({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JoinGroupBloc>(),
      child: _JoinGroupView(initialCode: initialCode),
    );
  }
}

class _JoinGroupView extends StatefulWidget {
  const _JoinGroupView({this.initialCode});

  final String? initialCode;

  @override
  State<_JoinGroupView> createState() => _JoinGroupViewState();
}

class _JoinGroupViewState extends State<_JoinGroupView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code = TextEditingController(
    text: widget.initialCode ?? '',
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.joinGroup),
      ),
      body: FairBackground(
        child: BlocConsumer<JoinGroupBloc, JoinGroupState>(
          listenWhen: (previous, current) =>
              previous.errorCode != current.errorCode ||
              previous.joined != current.joined,
          listener: (context, state) {
            if (state.errorCode != null) {
              showFairSnack(context, _error(context, state.errorCode!));
            }
            if (state.joined) {
              showFairSnack(context, l10n.joinedGroup);
              context.go('/home');
            }
          },
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                12,
                context.pagePadding,
                40,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: context.fair.brandGradient,
                            borderRadius: AppRadius.allLg,
                          ),
                          child: Icon(
                            Icons.link_rounded,
                            size: 34,
                            color: context.fair.onAccent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.joinTitle,
                          textAlign: TextAlign.center,
                          style: context.texts.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.joinSubtitle,
                          textAlign: TextAlign.center,
                          style: context.texts.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FairCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _code,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autofocus: widget.initialCode == null,
                                  decoration: InputDecoration(
                                    labelText: l10n.inviteCode,
                                    hintText: l10n.joinCodeHint,
                                    prefixIcon: const Icon(
                                      Icons.vpn_key_outlined,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _submit(context),
                                  validator: (value) =>
                                      (value ?? '').trim().length < 4
                                      ? l10n.invalidCode
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: state.joining
                                      ? null
                                      : () => _submit(context),
                                  icon: state.joining
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                  label: Text(l10n.join),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/groups/new'),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(l10n.createGroup),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.fair.infoSoft,
                            borderRadius: AppRadius.allMd,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                size: 18,
                                color: context.fair.info,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l10n.demoJoinHint,
                                  style: context.texts.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.authSecureNote,
                          textAlign: TextAlign.center,
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<JoinGroupBloc>().add(JoinGroupSubmitted(_code.text));
    }
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'invalid_code' => l10n.invalidCode,
      'invite_expired' => l10n.inviteExpired,
      'invite_not_found' => l10n.inviteNotFound,
      'already_member' => l10n.alreadyMember,
      'group_not_found' => l10n.groupNotFound,
      _ => l10n.joinFailed,
    };
  }
}
