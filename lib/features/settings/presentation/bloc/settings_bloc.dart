import 'dart:async';

import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/domain/usecases/settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);

  final AppThemeMode mode;
}

class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged(this.localeCode);

  final String localeCode;
}

class SettingsCurrencyChanged extends SettingsEvent {
  const SettingsCurrencyChanged(this.currency);

  final String currency;
}

class SettingsNotificationsChanged extends SettingsEvent {
  const SettingsNotificationsChanged(this.enabled);

  final bool enabled;
}

class SettingsPoliteRemindersChanged extends SettingsEvent {
  const SettingsPoliteRemindersChanged(this.enabled);

  final bool enabled;
}

class SettingsBloc extends Bloc<SettingsEvent, AppSettings> {
  SettingsBloc(this._watch, GetSettings get, this._update) : super(get()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsThemeChanged>(_onTheme);
    on<SettingsLocaleChanged>(_onLocale);
    on<SettingsCurrencyChanged>(_onCurrency);
    on<SettingsNotificationsChanged>(_onNotifications);
    on<SettingsPoliteRemindersChanged>(_onPoliteReminders);
    on<_SettingsChanged>(_onChanged);
    add(const SettingsStarted());
  }

  final WatchSettings _watch;
  final UpdateSettings _update;
  StreamSubscription<AppSettings>? _subscription;

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<AppSettings> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen((settings) {
      if (!isClosed) add(_SettingsChanged(settings));
    });
  }

  Future<void> _onTheme(
    SettingsThemeChanged event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(themeMode: event.mode);
    emit(next);
    await _update(next);
  }

  Future<void> _onLocale(
    SettingsLocaleChanged event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(localeCode: event.localeCode);
    emit(next);
    await _update(next);
  }

  Future<void> _onCurrency(
    SettingsCurrencyChanged event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(defaultCurrency: event.currency);
    emit(next);
    await _update(next);
  }

  Future<void> _onNotifications(
    SettingsNotificationsChanged event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(notificationsEnabled: event.enabled);
    emit(next);
    await _update(next);
  }

  Future<void> _onPoliteReminders(
    SettingsPoliteRemindersChanged event,
    Emitter<AppSettings> emit,
  ) async {
    final next = state.copyWith(politeReminders: event.enabled);
    emit(next);
    await _update(next);
  }

  void _onChanged(_SettingsChanged event, Emitter<AppSettings> emit) {
    if (event.settings != state) emit(event.settings);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _SettingsChanged extends SettingsEvent {
  const _SettingsChanged(this.settings);

  final AppSettings settings;
}
