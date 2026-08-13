import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/medicine_repository.dart';
import '../../../../core/repositories/settings_repository.dart';
import 'reminder_state.dart';

class ReminderCubit extends Cubit<ReminderState> {
  final MedicineRepository medicineRepository;
  final SettingsRepository settingsRepository;

  ReminderCubit({
    required this.medicineRepository,
    required this.settingsRepository,
  }) : super(ReminderInitial());

  void showReminder(String occurrenceId) {
    emit(ReminderLoading());
    try {
      final occurrence = medicineRepository.getAllOccurrences()
          .firstWhere((occ) => occ.id == occurrenceId);
      final medicine = medicineRepository.getMedicine(occurrence.medicineId);

      if (medicine != null) {
        emit(ReminderActive(occurrence: occurrence, medicine: medicine));
      } else {
        emit(const ReminderError('Medicine details not found.'));
      }
    } catch (e) {
      emit(ReminderError('Occurrence not found.'));
    }
  }

  Future<void> takeMedicine() async {
    if (state is ReminderActive) {
      final activeState = state as ReminderActive;
      emit(ReminderLoading());
      try {
        await medicineRepository.updateOccurrenceStatus(activeState.occurrence.id, 'taken');
        emit(const ReminderSuccess('Medicine marked as taken.'));
      } catch (e) {
        emit(ReminderError(e.toString()));
      }
    }
  }

  Future<void> skipMedicine() async {
    if (state is ReminderActive) {
      final activeState = state as ReminderActive;
      emit(ReminderLoading());
      try {
        await medicineRepository.updateOccurrenceStatus(activeState.occurrence.id, 'skipped');
        emit(const ReminderSuccess('Medicine marked as skipped.'));
      } catch (e) {
        emit(ReminderError(e.toString()));
      }
    }
  }

  Future<void> snoozeMedicine({int? customSnoozeMinutes}) async {
    if (state is ReminderActive) {
      final activeState = state as ReminderActive;
      emit(ReminderLoading());
      try {
        final settings = settingsRepository.getSettings();
        final snoozeTime = customSnoozeMinutes ?? settings.defaultSnoozeMinutes;
        await medicineRepository.snoozeOccurrence(activeState.occurrence.id, snoozeTime);
        emit(ReminderSuccess('Snoozed successfully.'));
      } catch (e) {
        emit(ReminderError(e.toString()));
      }
    }
  }
}
