import 'package:equatable/equatable.dart';
import '../../../../core/models/app_settings_model.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettingsModel settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}
