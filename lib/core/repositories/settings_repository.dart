import '../models/app_settings_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class SettingsRepository {
  AppSettingsModel getSettings() {
    return HiveService.settings;
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    await HiveService.saveSettings(newSettings);

    final now = DateTime.now();
    final futurePendingOccurrences = HiveService.occurrencesBox.values
        .where((occ) => occ.status == 'pending' && occ.scheduledAt.isAfter(now))
        .toList();

    // If notifications are disabled, cancel all scheduled notifications
    if (!newSettings.notificationsEnabled) {
      await NotificationService.cancelAllNotifications();
    } else {
      // Cancel outstanding notifications first to avoid duplicates
      await NotificationService.cancelAllNotifications();

      // Reschedule all future pending occurrences using the new settings
      for (final occ in futurePendingOccurrences) {
        final medicine = HiveService.medicinesBox.get(occ.medicineId);
        if (medicine != null && medicine.isActive) {
          final targetTime = occ.snoozedUntil ?? occ.scheduledAt;
          await NotificationService.scheduleNotification(
            id: occ.id,
            title: '💊 Medicine Reminder',
            body: '${medicine.name} (${medicine.strength}) - ${occ.dose}\n${occ.foodInstruction}',
            scheduledTime: targetTime,
            payload: occ.id,
            sound: newSettings.sound,
            vibration: newSettings.vibration,
            enabled: newSettings.notificationsEnabled,
          );
        }
      }
    }
  }
}
