import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 3)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  final String sound; // "default", "alarm2", "alarm3"

  @HiveField(1)
  final bool vibration;

  @HiveField(2)
  final int defaultSnoozeMinutes; // 5, 10, 15, 30

  @HiveField(3)
  final bool notificationsEnabled;

  AppSettingsModel({
    required this.sound,
    required this.vibration,
    required this.defaultSnoozeMinutes,
    required this.notificationsEnabled,
  });

  AppSettingsModel copyWith({
    String? sound,
    bool? vibration,
    int? defaultSnoozeMinutes,
    bool? notificationsEnabled,
  }) {
    return AppSettingsModel(
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
