import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import '../models/dose_occurrence_model.dart';
import '../models/medicine_model.dart';
import '../models/dose_model.dart';
import '../models/app_settings_model.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final occurrenceId = response.payload;
  final actionId = response.actionId;
  if (occurrenceId == null) return;

  // Initialize Hive in background isolate
  try {
    Hive.init(Directory.current.path); // Use default directory context for background
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicineModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DoseModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoseOccurrenceModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppSettingsModelAdapter());

    final occurrencesBox = await Hive.openBox<DoseOccurrenceModel>('occurrences_box');
    final occurrence = occurrencesBox.get(occurrenceId);
    if (occurrence == null) {
      await occurrencesBox.close();
      return;
    }

    final settingsBox = await Hive.openBox<AppSettingsModel>('settings_box');
    final settings = settingsBox.get('app_settings');
    final snoozeMinutes = settings?.defaultSnoozeMinutes ?? 10;
    final vibration = settings?.vibration ?? true;
    final sound = settings?.sound ?? 'default';
    final notificationsEnabled = settings?.notificationsEnabled ?? true;
    await settingsBox.close();

    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    if (actionId == 'taken') {
      final updated = occurrence.copyWith(
        status: 'taken',
        actionAt: DateTime.now(),
      );
      await occurrencesBox.put(occurrenceId, updated);
      await notificationsPlugin.cancel(occurrenceId.hashCode);
    } else if (actionId == 'skip') {
      final updated = occurrence.copyWith(
        status: 'skipped',
        actionAt: DateTime.now(),
      );
      await occurrencesBox.put(occurrenceId, updated);
      await notificationsPlugin.cancel(occurrenceId.hashCode);
    } else if (actionId == 'snooze') {
      final now = DateTime.now();
      final newScheduledAt = now.add(Duration(minutes: snoozeMinutes));
      final updated = occurrence.copyWith(
        snoozedUntil: () => newScheduledAt,
      );
      await occurrencesBox.put(occurrenceId, updated);

      // Reschedule the snoozed reminder in local notifications
      if (notificationsEnabled) {
        final medicineBox = await Hive.openBox<MedicineModel>('medicines_box');
        final medicine = medicineBox.get(occurrence.medicineId);
        final medicineName = medicine?.name ?? 'Medicine';
        final strength = medicine?.strength ?? '';
        await medicineBox.close();

        final tzScheduledTime = tz.TZDateTime.from(newScheduledAt, tz.local);

        final soundFile = sound == 'default' ? null : sound;
        final channelId = 'medicine_reminder_channel_${soundFile ?? 'default'}';
        final channelName = 'Medicine Reminders (${soundFile ?? 'Default'})';
        final androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Channel for medicine reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: soundFile != null ? RawResourceAndroidNotificationSound(soundFile) : null,
          playSound: notificationsEnabled,
          enableVibration: vibration,
          actions: [
            const AndroidNotificationAction('taken', '✓ Taken', showsUserInterface: false),
            const AndroidNotificationAction('snooze', '⏳ Snooze', showsUserInterface: false),
            const AndroidNotificationAction('skip', '❌ Skip', showsUserInterface: false),
          ],
        );

        final darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: notificationsEnabled,
          sound: soundFile != null ? '$soundFile.wav' : null,
          categoryIdentifier: 'medicine_reminder_category',
        );

        await notificationsPlugin.zonedSchedule(
          occurrence.id.hashCode,
          '💊 Medicine Reminder (Snoozed)',
          '$medicineName ($strength) - ${occurrence.dose}\n${occurrence.foodInstruction}',
          tzScheduledTime,
          NotificationDetails(android: androidDetails, iOS: darwinDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: occurrence.id,
        );
      }
    }

    await occurrencesBox.close();
  } catch (e) {
    // Log exception in background task
    print('Background Notification Action Error: $e');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String> selectNotificationStream =
      StreamController<String>.broadcast();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosCategory = DarwinNotificationCategory(
      'medicine_reminder_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('taken', '✓ Taken'),
        DarwinNotificationAction.plain('snooze', '⏳ Snooze'),
        DarwinNotificationAction.plain('skip', '❌ Skip'),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.customDismissAction,
      },
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [iosCategory],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && response.actionId == null) {
          selectNotificationStream.add(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission() ?? false;
      return granted;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    return false;
  }

  static Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String sound,
    required bool vibration,
    required bool enabled,
  }) async {
    if (!enabled) return;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final soundFile = sound == 'default' ? null : sound;
    final channelId = 'medicine_reminder_channel_${soundFile ?? 'default'}';
    final channelName = 'Medicine Reminders (${soundFile ?? 'Default'})';
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Channel for medicine reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: soundFile != null ? RawResourceAndroidNotificationSound(soundFile) : null,
      playSound: enabled,
      enableVibration: vibration,
      actions: [
        const AndroidNotificationAction('taken', '✓ Taken', showsUserInterface: false),
        const AndroidNotificationAction('snooze', '⏳ Snooze', showsUserInterface: false),
        const AndroidNotificationAction('skip', '❌ Skip', showsUserInterface: false),
      ],
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: enabled,
      sound: soundFile != null ? '$soundFile.wav' : null,
      categoryIdentifier: 'medicine_reminder_category',
    );

    await _notificationsPlugin.zonedSchedule(
      id.hashCode,
      title,
      body,
      tzScheduledTime,
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
