import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medicine_reminder/core/models/dose_model.dart';
import 'package:medicine_reminder/core/models/medicine_model.dart';
import 'package:medicine_reminder/core/models/dose_occurrence_model.dart';
import 'package:medicine_reminder/core/models/app_settings_model.dart';
import 'package:medicine_reminder/core/utils/occurrence_generator.dart';
import 'package:medicine_reminder/features/dashboard/presentation/bloc/dashboard_state.dart';

void main() {
  // Set up Hive with temporary directory before running tests
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicineModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DoseModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoseOccurrenceModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppSettingsModelAdapter());
  });

  group('Occurrence Generator Tests', () {
    test('Should generate exactly 21 occurrences for 7 days with 3 doses/day', () {
      final startDate = DateTime(2026, 8, 10, 0, 0);
      final endDate = DateTime(2026, 8, 16, 23, 59);

      final medicine = MedicineModel(
        id: 'med_1',
        name: 'Paracetamol',
        description: 'Pain relief',
        type: 'Tablet',
        strength: '500 mg',
        startDate: startDate,
        endDate: endDate,
        doses: [
          DoseModel(id: 'd1', time: '08:00', quantity: 1, unit: 'Tablet', foodInstruction: 'After Food'),
          DoseModel(id: 'd2', time: '13:00', quantity: 1, unit: 'Tablet', foodInstruction: 'After Food'),
          DoseModel(id: 'd3', time: '20:00', quantity: 1, unit: 'Tablet', foodInstruction: 'Before Food'),
        ],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final occurrences = OccurrenceGenerator.generateOccurrences(
        medicine: medicine,
        fromDateTime: startDate,
        toDateTime: endDate,
      );

      expect(occurrences.length, 21);

      // Verify snapshots contain medicine strength
      expect(occurrences.first.dose, '500 mg • 1 Tablet');
      expect(occurrences.first.foodInstruction, 'After Food');
      expect(occurrences.first.status, 'pending');

      // Verify the boundaries are correct
      expect(occurrences.first.scheduledAt, DateTime(2026, 8, 10, 8, 0));
      expect(occurrences.last.scheduledAt, DateTime(2026, 8, 16, 20, 0));
    });

    test('Should respect the generation window bounds when start date is after fromDateTime', () {
      final startDate = DateTime(2026, 8, 12, 0, 0);
      final endDate = DateTime(2026, 8, 16, 23, 59);

      final medicine = MedicineModel(
        id: 'med_2',
        name: 'Aspirin',
        description: 'Blood thinner',
        type: 'Tablet',
        strength: '75 mg',
        startDate: startDate,
        endDate: endDate,
        doses: [
          DoseModel(id: 'd1', time: '09:00', quantity: 1, unit: 'Tablet', foodInstruction: 'After Food'),
        ],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Generate from 10 Aug (prior to start date) to 16 Aug
      final occurrences = OccurrenceGenerator.generateOccurrences(
        medicine: medicine,
        fromDateTime: DateTime(2026, 8, 10, 0, 0),
        toDateTime: endDate,
      );

      // Should only generate for 12, 13, 14, 15, 16 Aug (5 occurrences)
      expect(occurrences.length, 5);
      expect(occurrences.first.scheduledAt, DateTime(2026, 8, 12, 9, 0));
    });
  });

  group('Dashboard State Stats Calculation Tests', () {
    test('Should calculate stats from occurrences correctly', () {
      final occurrences = [
        DoseOccurrenceModel(
          id: '1', medicineId: 'm1', doseId: 'd1',
          scheduledAt: DateTime.now(), dose: '1 Tab', foodInstruction: 'None',
          status: 'taken', createdAt: DateTime.now()
        ),
        DoseOccurrenceModel(
          id: '2', medicineId: 'm1', doseId: 'd1',
          scheduledAt: DateTime.now(), dose: '1 Tab', foodInstruction: 'None',
          status: 'pending', createdAt: DateTime.now()
        ),
        DoseOccurrenceModel(
          id: '3', medicineId: 'm1', doseId: 'd1',
          scheduledAt: DateTime.now(), dose: '1 Tab', foodInstruction: 'None',
          status: 'missed', createdAt: DateTime.now()
        ),
        DoseOccurrenceModel(
          id: '4', medicineId: 'm1', doseId: 'd1',
          scheduledAt: DateTime.now(), dose: '1 Tab', foodInstruction: 'None',
          status: 'skipped', createdAt: DateTime.now()
        ),
      ];

      final dashboardState = DashboardState(
        selectedDate: DateTime.now(),
        searchQuery: '',
        occurrences: occurrences,
        medicines: const {},
        status: DashboardStatus.loaded,
        errorMessage: '',
      );

      expect(dashboardState.totalDoses, 4);
      expect(dashboardState.takenDoses, 1);
      expect(dashboardState.pendingDoses, 1);
      expect(dashboardState.missedDoses, 1);
      expect(dashboardState.skippedDoses, 1);
    });
  });
}
