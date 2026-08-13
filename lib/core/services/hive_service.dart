import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine_model.dart';
import '../models/dose_model.dart';
import '../models/dose_occurrence_model.dart';
import '../models/app_settings_model.dart';

class HiveService {
  static const String medicinesBoxName = 'medicines_box';
  static const String occurrencesBoxName = 'occurrences_box';
  static const String settingsBoxName = 'settings_box';

  static late Box<MedicineModel> medicinesBox;
  static late Box<DoseOccurrenceModel> occurrencesBox;
  static late Box<AppSettingsModel> settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicineModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DoseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DoseOccurrenceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }

    // Open Boxes
    medicinesBox = await Hive.openBox<MedicineModel>(medicinesBoxName);
    occurrencesBox = await Hive.openBox<DoseOccurrenceModel>(occurrencesBoxName);
    settingsBox = await Hive.openBox<AppSettingsModel>(settingsBoxName);

    // Initialize Settings if Empty
    if (settingsBox.isEmpty) {
      final defaultSettings = AppSettingsModel(
        sound: 'default',
        vibration: true,
        defaultSnoozeMinutes: 10,
        notificationsEnabled: true,
      );
      await settingsBox.put('app_settings', defaultSettings);
    }
  }

  // Helper getters
  static AppSettingsModel get settings =>
      settingsBox.get('app_settings')!;

  static Future<void> saveSettings(AppSettingsModel newSettings) async {
    await settingsBox.put('app_settings', newSettings);
  }
}
