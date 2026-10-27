import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user)?.id ??
        getIt<AuthRepository>().currentUser?.id ??
        '';
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(ProfileStarted(userId)),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _name = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode ||
          previous.saved != current.saved,
      listener: (context, state) {
        if (state.errorCode != null) {
          showFairSnack(context, _error(context, state.errorCode!));
          context.read<ProfileBloc>().add(const ProfileMessageDismissed());
        }
        if (state.saved) {
          showFairSnack(context, l10n.profileSaved);
          context.read<ProfileBloc>().add(const ProfileMessageDismissed());
        }
      },
      builder: (context, state) {
        if (!_hydrated && !state.loading) {
          _hydrated = true;
          _name.text = state.displayName;
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/settings'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.profile),
          ),
          body: FairBackground(
            child: state.loading
                ? const LoadingState()
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      context.pagePadding,
                      AppSpacing.md,
                      context.pagePadding,
                      AppSpacing.xxl,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProfileIdentityCard(
                                name: state.displayName.trim().isEmpty
                                    ? l10n.t('Pengguna', 'User')
                                    : state.displayName,
                                email: state.profile?.email ?? '',
                                avatarUrl: state.profile?.avatarUrl,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FairCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l10n.displayName.toUpperCase(),
                                      style: context.texts.labelSmall?.copyWith(
                                        fontSize: 8.5,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (value) => context
                                          .read<ProfileBloc>()
                                          .add(ProfileNameChanged(value)),
                                      decoration: InputDecoration(
                                        hintText: l10n.displayName,
                                        prefixIcon: const Icon(
                                          Icons.badge_outlined,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      l10n.email.toUpperCase(),
                                      style: context.texts.labelSmall?.copyWith(
                                        fontSize: 8.5,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fair.surfaceMuted,
                                        borderRadius: AppRadius.allMd,
                                        border: Border.all(color: fair.line),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.alternate_email_rounded,
                                            size: 18,
                                            color: fair.inkMuted,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              state.profile?.email
                                                          .isNotEmpty ==
                                                      true
                                                  ? state.profile!.email
                                                  : l10n.t(
                                                      'Tanpa email',
                                                      'No email',
                                                    ),
                                              style: context.texts.bodyMedium,
                                            ),
                                          ),
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 15,
                                            color: fair.inkMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      l10n.defaultCurrency.toUpperCase(),
                                      style: context.texts.labelSmall?.copyWith(
                                        fontSize: 8.5,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      borderRadius: AppRadius.allMd,
                                      onTap: () async {
                                        final picked = await showCurrencyPicker(
                                          context,
                                          selected: state.defaultCurrency,
                                        );
                                        if (picked != null && context.mounted) {
                                          context.read<ProfileBloc>().add(
                                            ProfileCurrencyChanged(picked),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: fair.surfaceMuted,
                                          borderRadius: AppRadius.allMd,
                                          border: Border.all(color: fair.line),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  fair.accentSoft,
                                              child: Text(
                                                MoneyFormatter.symbolFor(
                                                  state.defaultCurrency,
                                                ),
                                                style: context.texts.labelSmall
                                                    ?.copyWith(
                                                      color: fair.accent,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    state.defaultCurrency,
                                                    style: context
                                                        .texts
                                                        .titleSmall,
                                                  ),
                                                  Text(
                                                    MoneyFormatter.names[state
                                                            .defaultCurrency] ??
                                                        '',
                                                    style: context
                                                        .texts
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.expand_more_rounded,
                                              size: 20,
                                              color: fair.inkMuted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FairCard(
                                tone: fair.blueSoft,
                                borderColor:
                                    fair.blue.withValues(alpha: 0.25),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 18,
                                      color: fair.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.t(
                                          'Nama ini yang dilihat temanmu di grup. Email hanya untuk masuk.',
                                          'Friends see this name in groups. Email is only for signing in.',
                                        ),
                                        style: context.texts.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: state.saving
                                    ? null
                                    : () => context.read<ProfileBloc>().add(
                                        const ProfileSubmitted(),
                                      ),
                                icon: state.saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  state.saving ? l10n.loading : l10n.save,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'name_required' => l10n.nameRequired,
      'save_failed' => l10n.saveFailed,
      _ => l10n.loadFailed,
    };
  }
}

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    final l10n = context.l10n;
    return FairCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: fair.accent, width: 2),
            ),
            child: AvatarCircle(name: name, imageUrl: avatarUrl, size: 76),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: context.texts.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            email.isEmpty ? l10n.t('Tanpa email', 'No email') : email,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall,
          ),
        ],
      ),
    );
  }
}
