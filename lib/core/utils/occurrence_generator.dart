import '../models/dose_occurrence_model.dart';
import '../models/medicine_model.dart';

class OccurrenceGenerator {
  static List<DoseOccurrenceModel> generateOccurrences({
    required MedicineModel medicine,
    required DateTime fromDateTime,
    required DateTime toDateTime,
  }) {
    final List<DoseOccurrenceModel> occurrences = [];
    
    // Normalize dates (start from the medicine's start date or fromDateTime, whichever is later)
    DateTime genStart = medicine.startDate.isAfter(fromDateTime) 
        ? medicine.startDate 
        : fromDateTime;
        
    DateTime genEnd = toDateTime;
    if (medicine.endDate != null && medicine.endDate!.isBefore(toDateTime)) {
      genEnd = medicine.endDate!;
    }
    
    // Normalize to date-only parts to calculate days correctly
    final startDateOnly = DateTime(genStart.year, genStart.month, genStart.day);
    final endDateOnly = DateTime(genEnd.year, genEnd.month, genEnd.day);
    
    if (startDateOnly.isAfter(endDateOnly)) {
      return [];
    }
    
    final daysCount = endDateOnly.difference(startDateOnly).inDays;
    
    for (int i = 0; i <= daysCount; i++) {
      final currentDay = startDateOnly.add(Duration(days: i));
      
      // Safety checks: double-check we don't generate outside medicine's limits
      if (_isDateBefore(currentDay, medicine.startDate)) continue;
      if (medicine.endDate != null && _isDateAfter(currentDay, medicine.endDate!)) continue;
      
      for (final dose in medicine.doses) {
        final timeParts = dose.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final scheduledTime = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day,
          hour,
          minute,
        );
        
        // Final bounds check on specific hour/minute
        if (scheduledTime.isBefore(medicine.startDate)) continue;
        if (medicine.endDate != null && scheduledTime.isAfter(medicine.endDate!)) continue;
        if (scheduledTime.isBefore(fromDateTime)) continue;
        if (scheduledTime.isAfter(toDateTime)) continue;
        
        // Generate a unique ID for this occurrence
        final occurrenceId = '${medicine.id}_${dose.id}_${scheduledTime.millisecondsSinceEpoch}';
        
        final doseString = medicine.strength.isNotEmpty
            ? '${medicine.strength} • ${dose.quantity % 1 == 0 ? dose.quantity.toInt() : dose.quantity} ${dose.unit}'
            : '${dose.quantity % 1 == 0 ? dose.quantity.toInt() : dose.quantity} ${dose.unit}';

        occurrences.add(DoseOccurrenceModel(
          id: occurrenceId,
          medicineId: medicine.id,
          doseId: dose.id,
          scheduledAt: scheduledTime,
          dose: doseString,
          foodInstruction: dose.foodInstruction,
          status: 'pending',
          createdAt: DateTime.now(),
        ));
      }
    }
    
    return occurrences;
  }

  static bool _isDateAfter(DateTime d1, DateTime d2) {
    final date1 = DateTime(d1.year, d1.month, d1.day);
    final date2 = DateTime(d2.year, d2.month, d2.day);
    return date1.isAfter(date2);
  }

  static bool _isDateBefore(DateTime d1, DateTime d2) {
    final date1 = DateTime(d1.year, d1.month, d1.day);
    final date2 = DateTime(d2.year, d2.month, d2.day);
    return date1.isBefore(date2);
  }
}
