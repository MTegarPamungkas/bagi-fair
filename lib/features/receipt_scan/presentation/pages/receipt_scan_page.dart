import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/bloc/receipt_scan_bloc.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_analyzing_stage.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_review_stage.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_save_bar.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_stepper.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_upload_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScanPage extends StatelessWidget {
  const ReceiptScanPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReceiptScanBloc>()..add(ReceiptScanStarted(groupId)),
      child: _ReceiptScanView(groupId: groupId),
    );
  }
}

class _ReceiptScanView extends StatefulWidget {
  const _ReceiptScanView({required this.groupId});

  final String groupId;

  @override
  State<_ReceiptScanView> createState() => _ReceiptScanViewState();
}

class _ReceiptScanViewState extends State<_ReceiptScanView> {
  final _merchant = TextEditingController();
  final _tax = TextEditingController();
  final _service = TextEditingController();
  final _picker = ImagePicker();

  bool _hydrated = false;
  bool _picking = false;
  String? _lastCurrency;

  @override
  void dispose() {
    _merchant.dispose();
    _tax.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    if (context.read<ReceiptScanBloc>().state.scanning) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 84,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > AppConfig.maxReceiptUploadBytes) {
        showFairSnack(context, context.l10n.imageTooLarge);
        return;
      }
      final mime = file.mimeType?.startsWith('image/') == true
          ? file.mimeType!
          : 'image/jpeg';
      context.read<ReceiptScanBloc>().add(
        ReceiptScanImageSelected(bytes: bytes, mimeType: mime),
      );
    } catch (error) {
      if (mounted) showFairSnack(context, context.l10n.permissionDenied);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _hydrate(ReceiptScanState state) {
    // Hydration must happen when the review stage appears, not on the first
    // (upload) frame. Previously the upload build marked it done, so the AI
    // merchant/tax/service values never reached their text fields.
    if (!state.manual) {
      _hydrated = false;
      return;
    }
    if (_hydrated) return;
    _hydrated = true;
    _merchant.text = state.merchant;
    _tax.text = state.taxMinor > 0
        ? MoneyFormatter.input(state.taxMinor, currency: state.currency)
        : '';
    _service.text = state.serviceMinor > 0
        ? MoneyFormatter.input(state.serviceMinor, currency: state.currency)
        : '';
  }

  void _syncMoneyFields(ReceiptScanState state) {
    if (state.currency == _lastCurrency) return;
    _lastCurrency = state.currency;
    if (state.taxMinor > 0) {
      _tax.text = MoneyFormatter.input(
        state.taxMinor,
        currency: state.currency,
      );
    }
    if (state.serviceMinor > 0) {
      _service.text = MoneyFormatter.input(
        state.serviceMinor,
        currency: state.currency,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ReceiptScanBloc, ReceiptScanState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode ||
          previous.saved != current.saved,
      listener: (context, state) {
        if (state.errorCode != null) {
          showFairSnack(context, _error(context, state.errorCode!));
          context.read<ReceiptScanBloc>().add(const ReceiptScanCleared());
        }
        if (state.saved && state.receiptId != null) {
          showFairSnack(context, l10n.receiptSaved);
          final uri = Uri(
            path: '/groups/${widget.groupId}/expenses/new',
            queryParameters: {'receiptId': state.receiptId!},
          );
          if (context.canPop()) {
            context.pushReplacement(uri.toString());
          } else {
            context.go(uri.toString());
          }
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _appBar(context, scanning: state.scanning),
            body: const FairBackground(child: LoadingState()),
          );
        }
        _hydrate(state);
        _syncMoneyFields(state);
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _appBar(context, scanning: state.scanning),
          body: FairBackground(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      context.pagePadding,
                      8,
                      context.pagePadding,
                      state.manual ? AppSpacing.lg : 120,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ScanStepper(manual: state.manual),
                              const SizedBox(height: AppSpacing.lg),
                              if (state.manual)
                                ScanReviewStage(
                                  state: state,
                                  merchant: _merchant,
                                  tax: _tax,
                                  service: _service,
                                  onPickAgain: () =>
                                      _pick(ImageSource.gallery),
                                  onEvent:
                                      context.read<ReceiptScanBloc>().add,
                                )
                              else if (state.scanning)
                                ScanAnalyzingStage(
                                  imageBytes: state.imageBytes,
                                )
                              else
                                ScanUploadStage(
                                  groupName: state.group?.name ?? '',
                                  picking: _picking,
                                  onCamera: () => _pick(ImageSource.camera),
                                  onGallery: () => _pick(ImageSource.gallery),
                                  onSample: () => context
                                      .read<ReceiptScanBloc>()
                                      .add(const ReceiptScanSampleRequested()),
                                  onManual: () => context
                                      .read<ReceiptScanBloc>()
                                      .add(const ReceiptScanManualRequested()),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.manual)
                  ScanSaveBar(
                    state: state,
                    onSave: () => context.read<ReceiptScanBloc>().add(
                      const ReceiptScanSubmitted(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(
    BuildContext context, {
    required bool scanning,
  }) {
    final l10n = context.l10n;
    return AppBar(
      backgroundColor: Colors.transparent,
      bottom: scanning
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: context.fair.accent,
              ),
            )
          : null,
      leading: IconButton(
        tooltip: l10n.back,
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go('/groups/${widget.groupId}'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(l10n.scanTitle),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Center(
            child: Pill(
              label: l10n.aiPowered,
              icon: Icons.auto_awesome_rounded,
              tone: context.fair.blue,
            ),
          ),
        ),
      ],
    );
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'rate_limited' => l10n.rateLimited,
      'cloud_unavailable' => l10n.aiNeedsCloud,
      'ai_not_configured' => l10n.aiNotConfigured,
      'receipt_incomplete' => l10n.receiptNotFound,
      'items_required' => l10n.itemsRequired,
      'save_failed' => l10n.saveFailed,
      _ => l10n.scanError,
    };
  }
}
