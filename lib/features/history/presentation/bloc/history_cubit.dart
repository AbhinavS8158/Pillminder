import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/medicine_repository.dart';
import '../../../../core/services/hive_service.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final MedicineRepository repository;
  StreamSubscription? _occurrencesSubscription;
  StreamSubscription? _medicinesSubscription;

  HistoryCubit(this.repository) : super(HistoryState.initial()) {
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

  Future<void> loadHistory() async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      // Sync missed occurrences first
      await repository.syncMissedOccurrences();

      final occurrences = repository.getAllOccurrences();
      final medicines = {
        for (var m in repository.getAllMedicines()) m.id: m
      };

      emit(state.copyWith(
        occurrences: occurrences,
        medicines: medicines,
        status: HistoryStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refreshData() async {
    try {
      await repository.syncMissedOccurrences();
      final occurrences = repository.getAllOccurrences();
      final medicines = {
        for (var m in repository.getAllMedicines()) m.id: m
      };
      emit(state.copyWith(
        occurrences: occurrences,
        medicines: medicines,
        status: HistoryStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void changeSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void changeStatusFilter(String filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void changeDateFilter(DateTime? date) {
    emit(state.copyWith(selectedDate: () => date));
  }
}
