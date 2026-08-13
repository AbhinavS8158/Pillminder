import '../models/medicine_model.dart';
import '../models/dose_occurrence_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../utils/occurrence_generator.dart';

class MedicineRepository {
  List<MedicineModel> getAllMedicines() {
    return HiveService.medicinesBox.values.toList();
  }

  List<MedicineModel> getActiveMedicines() {
    return HiveService.medicinesBox.values.where((m) => m.isActive).toList();
  }

  MedicineModel? getMedicine(String id) {
    return HiveService.medicinesBox.get(id);
  }

  List<DoseOccurrenceModel> getOccurrencesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return HiveService.occurrencesBox.values.where((occ) {
      return occ.scheduledAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          occ.scheduledAt.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<DoseOccurrenceModel> getAllOccurrences() {
    return HiveService.occurrencesBox.values.toList();
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    await HiveService.medicinesBox.put(medicine.id, medicine);

    // Generate occurrences
    final now = DateTime.now();
    final toDate = medicine.endDate ?? now.add(const Duration(days: 14));
    
    final occurrences = OccurrenceGenerator.generateOccurrences(
      medicine: medicine,
      fromDateTime: medicine.startDate.isBefore(now) ? medicine.startDate : now,
      toDateTime: toDate,
    );

    final settings = HiveService.settings;

    for (final occ in occurrences) {
      await HiveService.occurrencesBox.put(occ.id, occ);
      
      // Schedule notification
      if (occ.scheduledAt.isAfter(now)) {
        await NotificationService.scheduleNotification(
          id: occ.id,
          title: '💊 Medicine Reminder',
          body: '${medicine.name} (${medicine.strength}) - ${occ.dose}\n${occ.foodInstruction}',
          scheduledTime: occ.scheduledAt,
          payload: occ.id,
          sound: settings.sound,
          vibration: settings.vibration,
          enabled: settings.notificationsEnabled,
        );
      }
    }
  }

  Future<void> editMedicine(MedicineModel medicine) async {
    final oldMedicine = HiveService.medicinesBox.get(medicine.id);
    if (oldMedicine == null) return;

    // 1. Find all future pending occurrences for this medicine
    final now = DateTime.now();
    final futurePendingOccurrences = HiveService.occurrencesBox.values.where((occ) {
      return occ.medicineId == medicine.id &&
          occ.status == 'pending' &&
          occ.scheduledAt.isAfter(now);
    }).toList();

    // 2. Cancel scheduled notifications and delete them from Hive
    for (final occ in futurePendingOccurrences) {
      await NotificationService.cancelNotification(occ.id);
      await HiveService.occurrencesBox.delete(occ.id);
    }

    // 3. Save the updated medicine
    await HiveService.medicinesBox.put(medicine.id, medicine);

    // 4. Generate and schedule new occurrences from now
    if (medicine.isActive) {
      final toDate = medicine.endDate ?? now.add(const Duration(days: 14));
      
      // If start date is in the future, start generation from start date
      final genStart = medicine.startDate.isAfter(now) ? medicine.startDate : now;

      final newOccurrences = OccurrenceGenerator.generateOccurrences(
        medicine: medicine,
        fromDateTime: genStart,
        toDateTime: toDate,
      );

      final settings = HiveService.settings;

      for (final occ in newOccurrences) {
        await HiveService.occurrencesBox.put(occ.id, occ);
        
        if (occ.scheduledAt.isAfter(now)) {
          await NotificationService.scheduleNotification(
            id: occ.id,
            title: '💊 Medicine Reminder',
            body: '${medicine.name} (${medicine.strength}) - ${occ.dose}\n${occ.foodInstruction}',
            scheduledTime: occ.scheduledAt,
            payload: occ.id,
            sound: settings.sound,
            vibration: settings.vibration,
            enabled: settings.notificationsEnabled,
          );
        }
      }
    }
  }

  Future<void> deleteMedicine(String id) async {
    final now = DateTime.now();
    
    // 1. Get all future pending occurrences and cancel their notifications & delete them
    final futurePendingOccurrences = HiveService.occurrencesBox.values.where((occ) {
      return occ.medicineId == id &&
          occ.status == 'pending' &&
          occ.scheduledAt.isAfter(now);
    }).toList();

    for (final occ in futurePendingOccurrences) {
      await NotificationService.cancelNotification(occ.id);
      await HiveService.occurrencesBox.delete(occ.id);
    }

    // 2. Soft-delete the medicine (mark inactive) to retain past history in UI
    final medicine = HiveService.medicinesBox.get(id);
    if (medicine != null) {
      final updated = medicine.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await HiveService.medicinesBox.put(id, updated);
    }
  }

  Future<void> pauseMedicine(String id) async {
    final medicine = HiveService.medicinesBox.get(id);
    if (medicine == null || !medicine.isActive) return;

    // 1. Cancel and delete all future pending occurrences
    final now = DateTime.now();
    final futurePending = HiveService.occurrencesBox.values.where((occ) {
      return occ.medicineId == id &&
          occ.status == 'pending' &&
          occ.scheduledAt.isAfter(now);
    }).toList();

    for (final occ in futurePending) {
      await NotificationService.cancelNotification(occ.id);
      await HiveService.occurrencesBox.delete(occ.id);
    }

    // 2. Update active flag to false
    final updated = medicine.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    await HiveService.medicinesBox.put(id, updated);
  }

  Future<void> resumeMedicine(String id) async {
    final medicine = HiveService.medicinesBox.get(id);
    if (medicine == null || medicine.isActive) return;

    // 1. Update active flag to true
    final updated = medicine.copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );
    await HiveService.medicinesBox.put(id, updated);

    // 2. Re-generate and schedule future occurrences from now
    final now = DateTime.now();
    final toDate = updated.endDate ?? now.add(const Duration(days: 14));
    
    // Start generating from max of now and updated.startDate
    final genStart = updated.startDate.isAfter(now) ? updated.startDate : now;

    final occurrences = OccurrenceGenerator.generateOccurrences(
      medicine: updated,
      fromDateTime: genStart,
      toDateTime: toDate,
    );

    final settings = HiveService.settings;

    for (final occ in occurrences) {
      await HiveService.occurrencesBox.put(occ.id, occ);
      
      if (occ.scheduledAt.isAfter(now)) {
        await NotificationService.scheduleNotification(
          id: occ.id,
          title: '💊 Medicine Reminder',
          body: '${updated.name} (${updated.strength}) - ${occ.dose}\n${occ.foodInstruction}',
          scheduledTime: occ.scheduledAt,
          payload: occ.id,
          sound: settings.sound,
          vibration: settings.vibration,
          enabled: settings.notificationsEnabled,
        );
      }
    }
  }

  Future<void> updateOccurrenceStatus(String occurrenceId, String status, {DateTime? actionAt}) async {
    final occurrence = HiveService.occurrencesBox.get(occurrenceId);
    if (occurrence == null) return;

    final updated = occurrence.copyWith(
      status: status,
      actionAt: actionAt ?? DateTime.now(),
    );
    await HiveService.occurrencesBox.put(occurrenceId, updated);

    // Cancel notification as it has been acted upon
    await NotificationService.cancelNotification(occurrenceId);
  }

  Future<void> snoozeOccurrence(String occurrenceId, int snoozeMinutes) async {
    final occurrence = HiveService.occurrencesBox.get(occurrenceId);
    if (occurrence == null) return;

    final now = DateTime.now();
    final newScheduledTime = now.add(Duration(minutes: snoozeMinutes));

    final updated = occurrence.copyWith(
      snoozedUntil: () => newScheduledTime,
    );
    await HiveService.occurrencesBox.put(occurrenceId, updated);

    // Cancel old notification
    await NotificationService.cancelNotification(occurrenceId);

    // Schedule new notification
    final medicine = HiveService.medicinesBox.get(occurrence.medicineId);
    final settings = HiveService.settings;

    if (settings.notificationsEnabled) {
      await NotificationService.scheduleNotification(
        id: occurrenceId,
        title: '💊 Medicine Reminder (Snoozed)',
        body: '${medicine?.name ?? 'Medicine'} (${medicine?.strength ?? ''}) - ${occurrence.dose}\n${occurrence.foodInstruction}',
        scheduledTime: newScheduledTime,
        payload: occurrenceId,
        sound: settings.sound,
        vibration: settings.vibration,
        enabled: settings.notificationsEnabled,
      );
    }
  }

  Future<void> syncMissedOccurrences() async {
    final now = DateTime.now();
    final pendingPastOccurrences = HiveService.occurrencesBox.values.where((occ) {
      // It's past scheduled time, and hasn't been snoozed beyond now
      final effectiveScheduledTime = occ.snoozedUntil ?? occ.scheduledAt;
      return occ.status == 'pending' && effectiveScheduledTime.isBefore(now);
    }).toList();

    for (final occ in pendingPastOccurrences) {
      final updated = occ.copyWith(status: 'missed');
      await HiveService.occurrencesBox.put(occ.id, updated);
      // Cancel outstanding notification just in case
      await NotificationService.cancelNotification(occ.id);
    }
  }

  Future<void> syncOngoingOccurrences() async {
    final now = DateTime.now();
    final targetEndDate = now.add(const Duration(days: 14));
    final activeOngoingMedicines = HiveService.medicinesBox.values
        .where((m) => m.isActive && m.endDate == null)
        .toList();

    for (final medicine in activeOngoingMedicines) {
      // Find the latest occurrence scheduled for this medicine
      final existingOccurrences = HiveService.occurrencesBox.values
          .where((o) => o.medicineId == medicine.id)
          .toList();

      DateTime lastScheduledDate = medicine.startDate;
      if (existingOccurrences.isNotEmpty) {
        existingOccurrences.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        lastScheduledDate = existingOccurrences.last.scheduledAt;
      }

      // If the latest scheduled occurrence is less than 7 days from now,
      // generate and schedule the next 14 days of occurrences
      if (lastScheduledDate.difference(now).inDays < 7) {
        final startGen = lastScheduledDate.add(const Duration(seconds: 1));
        final newOccurrences = OccurrenceGenerator.generateOccurrences(
          medicine: medicine,
          fromDateTime: startGen,
          toDateTime: targetEndDate,
        );

        final settings = HiveService.settings;

        for (final occ in newOccurrences) {
          await HiveService.occurrencesBox.put(occ.id, occ);
          
          if (occ.scheduledAt.isAfter(now)) {
            await NotificationService.scheduleNotification(
              id: occ.id,
              title: '💊 Medicine Reminder',
              body: '${medicine.name} (${medicine.strength}) - ${occ.dose}\n${occ.foodInstruction}',
              scheduledTime: occ.scheduledAt,
              payload: occ.id,
              sound: settings.sound,
              vibration: settings.vibration,
              enabled: settings.notificationsEnabled,
            );
          }
        }
      }
    }
  }
}
