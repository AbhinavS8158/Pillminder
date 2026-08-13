import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/app_settings_model.dart';
import '../../../../core/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;

  SettingsCubit(this.repository) : super(SettingsLoading());

  void loadSettings() {
    final settings = repository.getSettings();
    emit(SettingsLoaded(settings));
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    emit(SettingsLoading());
    await repository.updateSettings(newSettings);
    emit(SettingsLoaded(newSettings));
  }

  Future<void> updateSound(String sound) async {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      final updated = current.copyWith(sound: sound);
      await updateSettings(updated);
    }
  }

  Future<void> toggleVibration(bool vibration) async {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      final updated = current.copyWith(vibration: vibration);
      await updateSettings(updated);
    }
  }

  Future<void> updateDefaultSnooze(int snoozeMinutes) async {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      final updated = current.copyWith(defaultSnoozeMinutes: snoozeMinutes);
      await updateSettings(updated);
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (state is SettingsLoaded) {
      final current = (state as SettingsLoaded).settings;
      final updated = current.copyWith(notificationsEnabled: enabled);
      await updateSettings(updated);
    }
  }
}
