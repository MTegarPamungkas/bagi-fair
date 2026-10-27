import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The three loading / empty / error surfaces every screen is expected to have.

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message, this.padding = AppSpacing.xxl});

  final String? message;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: context.fair.accent,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: context.texts.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.padding = AppSpacing.xxl,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: fair.surface,
                    borderRadius: AppRadius.allMd,
                    border: Border.all(color: fair.line, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: fair.shadow,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 27, color: fair.accent),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.texts.headlineSmall,
              ),
              if (body != null && body!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(
                    color: fair.inkMuted,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.padding = AppSpacing.xxl,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title ?? context.l10n.loadFailed,
      body: message,
      padding: padding,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
            ),
    );
  }
}
