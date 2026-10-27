import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/responsive/app_breakpoints.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/core/widgets/pickers.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/allocation_card.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_basics_card.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_form_controllers.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/expense_preview_card.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/itemized_card.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/participants_card.dart';
import 'package:bagi_fair/features/expense_form/presentation/widgets/split_mode_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ExpenseFormPage extends StatelessWidget {
  const ExpenseFormPage({super.key, required this.request});

  final ExpenseFormRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ExpenseFormBloc>(param1: request)..add(ExpenseFormStarted()),
      child: _ExpenseFormView(request: request),
    );
  }
}

class _ExpenseFormView extends StatefulWidget {
  const _ExpenseFormView({required this.request});

  final ExpenseFormRequest request;

  @override
  State<_ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends State<_ExpenseFormView> {
  final _controllers = ExpenseFormControllers();

  bool _hydrated = false;
  String? _lastCurrency;

  /// The signed-in user, not the payer: an expense paid by a friend must never
  /// be labelled "(Kamu)".
  String? _currentUserId(BuildContext context) =>
      context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ExpenseFormBloc, ExpenseFormState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode ||
          previous.saved != current.saved,
      listener: (context, state) {
        if (state.errorCode != null) {
          showFairSnack(context, _error(context, state.errorCode!));
          context.read<ExpenseFormBloc>().add(
            const ExpenseFormMessageDismissed(),
          );
        }
        if (state.saved) {
          showFairSnack(context, l10n.expenseSaved);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/groups/${widget.request.groupId}');
          }
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _appBar(context, l10n.addExpenseTitle),
            body: const FairBackground(child: LoadingState()),
          );
        }
        _sync(state);
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _appBar(
            context,
            state.isEditing ? l10n.editExpense : l10n.addExpenseTitle,
            receiptLinked: state.receiptId != null,
          ),
          body: FairBackground(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                12,
                context.pagePadding,
                120,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpenseBasicsCard(
                          state: state,
                          controllers: _controllers,
                          currentUserId: _currentUserId(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SplitModeCard(state: state),
                        const SizedBox(height: AppSpacing.md),
                        ParticipantsCard(
                          state: state,
                          currentUserId: _currentUserId(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (state.splitMode == SplitMode.itemized)
                          ItemizedCard(state: state, controllers: _controllers)
                        else
                          AllocationCard(
                            state: state,
                            controllers: _controllers,
                          ),
                        const SizedBox(height: AppSpacing.md),
                        ExpensePreviewCard(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                8,
                context.pagePadding,
                12,
              ),
              child: FilledButton.icon(
                onPressed: state.saving
                    ? null
                    : () => context.read<ExpenseFormBloc>().add(
                        const ExpenseFormSubmitted(),
                      ),
                icon: state.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  state.isEditing ? l10n.updateExpense : l10n.saveExpense,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _appBar(
    BuildContext context,
    String title, {
    bool receiptLinked = false,
  }) {
    return AppBar(
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(title),
      actions: [
        if (receiptLinked)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Pill(
              label: context.l10n.receiptLinked,
              icon: Icons.document_scanner_outlined,
              tone: context.fair.info,
            ),
          ),
      ],
    );
  }

  void _sync(ExpenseFormState state) {
    final c = _controllers;
    if (!_hydrated) {
      c.title.text = state.title;
      c.amount.text = state.amountMinor == 0
          ? ''
          : MoneyFormatter.input(state.amountMinor, currency: state.currency);
      c.note.text = state.note;
      c.fx.text = state.isForeignCurrency ? _rateText(state.fxRate) : '';
      c.tax.text = state.taxMinor == 0
          ? ''
          : MoneyFormatter.input(state.taxMinor, currency: state.currency);
      c.service.text = state.serviceMinor == 0
          ? ''
          : MoneyFormatter.input(state.serviceMinor, currency: state.currency);
      c.discount.text = state.discountMinor == 0
          ? ''
          : MoneyFormatter.input(state.discountMinor, currency: state.currency);
      _hydrated = true;
      _lastCurrency = state.currency;
    } else if (_lastCurrency != state.currency) {
      _lastCurrency = state.currency;
      c.amount.text = state.amountMinor == 0
          ? ''
          : MoneyFormatter.input(state.amountMinor, currency: state.currency);
      c.tax.text = state.taxMinor == 0
          ? ''
          : MoneyFormatter.input(state.taxMinor, currency: state.currency);
      c.service.text = state.serviceMinor == 0
          ? ''
          : MoneyFormatter.input(state.serviceMinor, currency: state.currency);
      c.discount.text = state.discountMinor == 0
          ? ''
          : MoneyFormatter.input(state.discountMinor, currency: state.currency);
    }
    for (final id in state.participantIds) {
      c.percent.putIfAbsent(
        id,
        () => TextEditingController(
          text: _percentText(state.weightsBps[id] ?? 0),
        ),
      );
      c.exact.putIfAbsent(
        id,
        () => TextEditingController(
          text: (state.exactMinor[id] ?? 0) == 0
              ? ''
              : MoneyFormatter.input(
                  state.exactMinor[id]!,
                  currency: state.currency,
                ),
        ),
      );
    }
    final itemIds = state.items.map((item) => item.id).toSet();
    for (final item in state.items) {
      c.items.putIfAbsent(item.id, () {
        final controllers = ItemControllers();
        controllers.name.text = item.name;
        controllers.quantity.text = item.quantity.toString();
        controllers.price.text = item.unitPriceMinor == 0
            ? ''
            : MoneyFormatter.input(
                item.unitPriceMinor,
                currency: state.currency,
              );
        return controllers;
      });
    }
    for (final id in [...c.items.keys]) {
      if (!itemIds.contains(id)) {
        c.items.remove(id)?.dispose();
      }
    }
  }

  String _percentText(int bps) =>
      bps == 0 ? '' : (bps / 100).toStringAsFixed(bps % 100 == 0 ? 0 : 2);

  String _rateText(double rate) {
    if (rate == rate.roundToDouble()) return rate.toStringAsFixed(0);
    return rate.toString();
  }

  String _error(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'title_required' => l10n.titleRequired,
      'amount_required' => l10n.amountRequired,
      'payer_required' => l10n.payerRequired,
      'participant_required' => l10n.participantRequired,
      'items_required' => l10n.itemsRequired,
      'item_unassigned' => l10n.itemUnassigned,
      'percentage_total' => l10n.percentageTotal,
      'exact_total' => l10n.exactTotal,
      'fx_invalid' => l10n.somethingWrong,
      'group_not_found' => l10n.groupNotFound,
      _ => l10n.saveFailed,
    };
  }
}
