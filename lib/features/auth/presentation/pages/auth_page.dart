import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/auth/presentation/widgets/auth_brand_panel.dart';
import 'package:bagi_fair/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: context.fair.background,
      body: FairBackground(
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.errorCode != current.errorCode,
            listener: (context, state) {
              if (state.errorCode != null) {
                showFairSnack(context, _errorText(context, state.errorCode!));
                context.read<AuthBloc>().add(const AuthMessageDismissed());
              }
            },
            builder: (context, state) {
              final form = AuthFormCard(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                signUp: _signUp,
                obscure: _obscure,
                busy: state.busy,
                notice: state.notice,
                onToggleMode: () => setState(() => _signUp = !_signUp),
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmit: () => _submit(context),
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.pagePadding,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - AppSpacing.xl * 2,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: wide ? 1060 : 480,
                          ),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      flex: 6,
                                      child: AuthBrandPanel(),
                                    ),
                                    const SizedBox(width: AppSpacing.huge),
                                    Expanded(flex: 4, child: form),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const AuthBrandPanel(compact: true),
                                    const SizedBox(height: AppSpacing.xl),
                                    form,
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEmailRequested(
        email: _emailController.text,
        password: _passwordController.text,
        isSignUp: _signUp,
        displayName: _nameController.text,
      ),
    );
  }

  String _errorText(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'email_invalid' => l10n.emailInvalid,
      'password_short' => l10n.passwordShort,
      'invalid_credentials' => l10n.invalidCredentials,
      'email_not_confirmed' => l10n.emailNotConfirmed,
      'email_in_use' => l10n.emailInUse,
      'rate_limited' => l10n.emailRateLimit,
      'network' => l10n.networkError,
      _ => l10n.somethingWrong,
    };
  }
}
