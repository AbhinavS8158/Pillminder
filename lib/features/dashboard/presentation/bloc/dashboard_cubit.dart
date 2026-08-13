import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/medicine_repository.dart';
import '../../../../core/services/hive_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final MedicineRepository repository;
  StreamSubscription? _occurrencesSubscription;
  StreamSubscription? _medicinesSubscription;

  DashboardCubit(this.repository) : super(DashboardState.initial()) {
    // Listen to changes in both boxes to refresh UI automatically
    _occurrencesSubscription = HiveService.occurrencesBox.watch().listen((_) {
      refreshData();
    });
    _medicinesSubscription = HiveService.medicinesBox.watch().listen((_) {
      refreshData();
    });
  }

  @override
  Future<void> close() {
    _occurrencesSubscription?.cancel();
    _medicinesSubscription?.cancel();
    return super.close();
  }

  Future<void> loadDashboardData({DateTime? date, String? search}) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final selectedDate = date ?? state.selectedDate;
      final query = search ?? state.searchQuery;

      // Sync missed and ongoing occurrences before loading data
      await repository.syncMissedOccurrences();
      await repository.syncOngoingOccurrences();

      final occurrences = repository.getOccurrencesForDate(selectedDate);
      final medicines = {
        for (var m in repository.getAllMedicines()) m.id: m
      };

      emit(state.copyWith(
        selectedDate: selectedDate,
        searchQuery: query,
        occurrences: occurrences,
        medicines: medicines,
        status: DashboardStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refreshData() async {
    // Load without explicitly resetting to loading state for smooth micro-animations
    try {
      await repository.syncMissedOccurrences();
      final occurrences = repository.getOccurrencesForDate(state.selectedDate);
      final medicines = {
        for (var m in repository.getAllMedicines()) m.id: m
      };
      emit(state.copyWith(
        occurrences: occurrences,
        medicines: medicines,
        status: DashboardStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void changeDate(DateTime date) {
    loadDashboardData(date: date);
  }

  void changeSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> takeOccurrence(String id) async {
    try {
      await repository.updateOccurrenceStatus(id, 'taken');
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> skipOccurrence(String id) async {
    try {
      await repository.updateOccurrenceStatus(id, 'skipped');
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> snoozeOccurrence(String id, int minutes) async {
    try {
      await repository.snoozeOccurrence(id, minutes);
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.error, errorMessage: e.toString()));
    }
  }
}
