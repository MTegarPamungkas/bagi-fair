import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/data/services/share_service.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/group_detail/presentation/bloc/group_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupMenu extends StatelessWidget {
  const GroupMenu({super.key, required this.group, required this.state});

  final Group group;
  final GroupDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.groupSettings,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) async {
        final bloc = context.read<GroupDetailBloc>();
        switch (value) {
          case 'csv':
            bloc.add(const GroupDetailExportRequested(pdf: false));
          case 'pdf':
            bloc.add(const GroupDetailExportRequested(pdf: true));
          case 'share':
            final locale = l10n.locale.languageCode;
            final lines = <String>[
              '${l10n.groups} · ${group.name}',
              '${l10n.totalGroupSpend}: ${MoneyFormatter.format(state.summary.totalExpenseMinor, currency: group.currency, localeCode: locale)}',
              '${l10n.yourShare}: ${MoneyFormatter.format(state.summary.yourShareMinor, currency: group.currency, localeCode: locale)}',
              if (state.summary.transfers.isEmpty) l10n.impasTitle,
              for (final transfer in state.summary.transfers)
                '${state.nameFor(transfer.fromUserId)} → ${state.nameFor(transfer.toUserId)}: ${MoneyFormatter.format(transfer.amountMinor, currency: group.currency, localeCode: locale)}',
            ];
            await getIt<ShareService>().shareToWhatsApp(lines.join('\n'));
          case 'archive':
            final confirmed = await showFairConfirm(
              context,
              title: l10n.archiveGroup,
              body: l10n.archiveGroupBody,
              confirmLabel: l10n.archiveGroup,
            );
            if (confirmed) bloc.add(const GroupDetailArchiveRequested());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: const Icon(Icons.chat_rounded, size: 20),
            title: Text(l10n.shareGroupSummary),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          child: ListTile(
            leading: const Icon(Icons.table_view_rounded, size: 20),
            title: Text(l10n.exportCsv),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            title: Text(l10n.exportPdf),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (state.isOwner)
          PopupMenuItem(
            value: 'archive',
            child: ListTile(
              leading: Icon(
                Icons.archive_outlined,
                size: 20,
                color: context.fair.negative,
              ),
              title: Text(
                l10n.archiveGroup,
                style: TextStyle(color: context.fair.negative),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}
