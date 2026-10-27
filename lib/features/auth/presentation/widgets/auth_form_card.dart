import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:flutter/material.dart';

/// Email + password form. Google OAuth is intentionally absent until the
/// provider is configured on the Supabase project.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.signUp,
    required this.obscure,
    required this.busy,
    required this.notice,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool signUp;
  final bool obscure;
  final bool busy;
  final String? notice;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    return FairCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              signUp ? l10n.signUp : l10n.signIn,
              style: context.texts.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              signUp ? l10n.signUpSubtitle : l10n.signInSubtitle,
              style: context.texts.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.signIn)),
                ButtonSegment(value: true, label: Text(l10n.signUp)),
              ],
              selected: {signUp},
              showSelectedIcon: false,
              onSelectionChanged: busy
                  ? null
                  : (selection) {
                      if (selection.first != signUp) onToggleMode();
                    },
            ),
            if (notice == 'confirm_email') ...[
              const SizedBox(height: AppSpacing.md),
              _NoticeBanner(
                icon: Icons.mark_email_read_outlined,
                text: l10n.emailConfirmationSent,
                tone: fair.info,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (signUp) ...[
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.displayName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextFormField(
              key: const Key('auth-email'),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return l10n.emailRequired;
                if (!text.contains('@') || !text.contains('.')) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('auth-password'),
              controller: passwordController,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  tooltip: obscure
                      ? l10n.t('Tampilkan sandi', 'Show password')
                      : l10n.t('Sembunyikan sandi', 'Hide password'),
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) return l10n.passwordRequired;
                if ((value ?? '').length < 6) return l10n.passwordShort;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: busy ? null : onSubmit,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(signUp ? l10n.createAccount : l10n.signIn),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, size: 14, color: fair.inkMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.t(
                      'Akun & data tersimpan di Supabase.',
                      'Account & data live in Supabase.',
                    ),
                    style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.texts.bodySmall)),
        ],
      ),
    );
  }
}
