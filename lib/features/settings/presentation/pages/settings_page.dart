import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:bagi_fair/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    return _SettingsView(user: user);
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final sync = context.watch<SyncBloc>().state;
    return FairBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pagePadding,
          18,
          context.pagePadding,
          120,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    eyebrow: l10n.you,
                    title: l10n.settings,
                    subtitle: l10n.settingsSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AccountCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.palette_outlined,
                    title: l10n.appearance,
                    children: [
                      _LabeledBlock(
                        label: l10n.theme,
                        child: SegmentedButton<AppThemeMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: AppThemeMode.system,
                              icon: const Icon(Icons.brightness_auto_rounded),
                              label: Text(l10n.themeSystem),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.light,
                              icon: const Icon(Icons.light_mode_outlined),
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.dark,
                              icon: const Icon(Icons.dark_mode_outlined),
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (selection) {
                            context.read<SettingsBloc>().add(
                              SettingsThemeChanged(selection.first),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledBlock(
                        label: l10n.language,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: 'id',
                              label: Text(l10n.indonesian),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.english),
                            ),
                          ],
                          selected: {settings.localeCode},
                          onSelectionChanged: (selection) {
                            context.read<SettingsBloc>().add(
                              SettingsLocaleChanged(selection.first),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.tune_rounded,
                    title: l10n.t('Preferensi', 'Preferences'),
                    children: [
                      _ActionRow(
                        icon: Icons.payments_outlined,
                        title: l10n.defaultCurrency,
                        subtitle:
                            '${settings.defaultCurrency} · ${MoneyFormatter.names[settings.defaultCurrency] ?? ''}',
                        onTap: () async {
                          final picked = await showCurrencyPicker(
                            context,
                            selected: settings.defaultCurrency,
                          );
                          if (picked != null && context.mounted) {
                            context.read<SettingsBloc>().add(
                              SettingsCurrencyChanged(picked),
                            );
                          }
                        },
                      ),
                      Divider(color: context.fair.line),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: settings.notificationsEnabled,
                        onChanged: (value) => context.read<SettingsBloc>().add(
                          SettingsNotificationsChanged(value),
                        ),
                        title: Text(
                          l10n.notifications,
                          style: context.texts.titleSmall,
                        ),
                        subtitle: Text(
                          l10n.notificationsHint,
                          style: context.texts.bodySmall,
                        ),
                        secondary: Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: context.fair.accent,
                        ),
                      ),
                      Divider(color: context.fair.line),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: settings.politeReminders,
                        onChanged: (value) => context.read<SettingsBloc>().add(
                          SettingsPoliteRemindersChanged(value),
                        ),
                        title: Text(
                          l10n.politeReminders,
                          style: context.texts.titleSmall,
                        ),
                        subtitle: Text(
                          l10n.politeRemindersHint,
                          style: context.texts.bodySmall,
                        ),
                        secondary: Icon(
                          Icons.favorite_outline_rounded,
                          size: 20,
                          color: context.fair.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SyncCard(status: sync),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.ios_share_rounded,
                    title: l10n.exportSection,
                    children: [
                      Text(l10n.exportHint, style: context.texts.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      _ExportButtons(
                        onOpen: (groups) => _openGroup(context, groups),
                        onEmpty: () =>
                            showFairSnack(context, l10n.exportNeedsGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: l10n.about,
                    children: [
                      Text(l10n.aboutBody, style: context.texts.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                      _InfoLine(
                        icon: Icons.verified_user_outlined,
                        title: l10n.dataSecurity,
                        body: l10n.dataSecurityBody,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoLine(
                        icon: Icons.tag_rounded,
                        title: l10n.version,
                        body:
                            '${AppConfig.appName} 1.0.0 · ${l10n.cloudMode}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: context.fair.negative,
                    ),
                    label: Text(
                      l10n.signOut,
                      style: TextStyle(color: context.fair.negative),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGroup(BuildContext context, List<Group> groups) async {
    final selected = await showGroupPicker(
      context,
      groups: groups,
      title: context.l10n.exportSection,
    );
    if (selected == null || !context.mounted) return;
    context.push('/groups/${selected.id}');
    showFairSnack(context, context.l10n.exportHint);
  }

  Future<void> _signOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showFairConfirm(
      context,
      title: l10n.signOutConfirm,
      body: l10n.signOutBody,
      confirmLabel: l10n.signOut,
    );
    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayName = user?.displayName ?? l10n.t('Tamu', 'Guest');
    return FairCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AvatarCircle(
            name: displayName,
            imageUrl: user?.avatarUrl,
            size: 54,
            highlight: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email.isNotEmpty == true
                      ? user!.email
                      : l10n.t(
                          'Mode lokal tanpa akun',
                          'Local mode, no account',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: l10n.profile,
            onPressed: () => context.push('/settings/profile'),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FairCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.fair.accent),
              const SizedBox(width: 8),
              Text(title, style: context.texts.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _ExportButtons extends StatefulWidget {
  const _ExportButtons({required this.onOpen, required this.onEmpty});

  final ValueChanged<List<Group>> onOpen;
  final VoidCallback onEmpty;

  @override
  State<_ExportButtons> createState() => _ExportButtonsState();
}

class _ExportButtonsState extends State<_ExportButtons> {
  late final Future<List<Group>> _groups = _load();

  Future<List<Group>> _load() async {
    try {
      final groups = await getIt<WatchGroups>()().first;
      return groups.where((group) => !group.archived).toList(growable: false);
    } catch (error) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<Group>>(
      future: _groups,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const <Group>[];
        final loading = snapshot.connectionState == ConnectionState.waiting;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : groups.isEmpty
                  ? widget.onEmpty
                  : () => widget.onOpen(groups),
              icon: const Icon(Icons.table_view_outlined, size: 17),
              label: Text(l10n.exportCsv),
            ),
            OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : groups.isEmpty
                  ? widget.onEmpty
                  : () => widget.onOpen(groups),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
              label: Text(l10n.exportPdf),
            ),
          ],
        );
      },
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  const _LabeledBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            fontSize: 8.5,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: child),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.allMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.fair.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.texts.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.fair.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fair = context.fair;
    final locale = l10n.locale.languageCode;
    return _SectionCard(
      icon: Icons.cloud_sync_outlined,
      title: l10n.syncSection,
      children: [
        Row(
          children: [
            SyncChip(
              status: status,
              onTap: () => context.read<SyncBloc>().add(const SyncRequested()),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: status.phase == SyncPhase.syncing
                  ? null
                  : () => context.read<SyncBloc>().add(const SyncRequested()),
              icon: const Icon(Icons.sync_rounded, size: 17),
              label: Text(l10n.syncNow),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        InfoRow(
          label: l10n.pendingChanges,
          value: '${status.pendingCount}',
          icon: Icons.inbox_outlined,
        ),
        InfoRow(
          label: l10n.lastSync,
          value: status.lastSyncedAt == null
              ? l10n.never
              : AppDates.relative(status.lastSyncedAt!, localeCode: locale),
          icon: Icons.schedule_rounded,
        ),
        if (status.phase == SyncPhase.error && status.message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            status.message!,
            style: context.texts.bodySmall?.copyWith(color: fair.negative),
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: context.fair.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.titleSmall),
              const SizedBox(height: 2),
              Text(body, style: context.texts.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
