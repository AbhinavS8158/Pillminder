import 'package:equatable/equatable.dart';
import '../../../../core/models/dose_occurrence_model.dart';
import '../../../../core/models/medicine_model.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState extends Equatable {
  final String searchQuery;
  final String statusFilter; // 'all', 'taken', 'missed', 'skipped'
  final DateTime? selectedDate;
  final List<DoseOccurrenceModel> occurrences;
  final Map<String, MedicineModel> medicines;
  final HistoryStatus status;
  final String errorMessage;

  const HistoryState({
    required this.searchQuery,
    required this.statusFilter,
    this.selectedDate,
    required this.occurrences,
    required this.medicines,
    required this.status,
    required this.errorMessage,
  });

  factory HistoryState.initial() {
    return HistoryState(
      searchQuery: '',
      statusFilter: 'all',
      selectedDate: null,
      occurrences: const [],
      medicines: const {},
      status: HistoryStatus.initial,
      errorMessage: '',
    );
  }

  List<DoseOccurrenceModel> get filteredOccurrences {
    // Sort reverse-chronologically (newest first)
    final sorted = List<DoseOccurrenceModel>.from(occurrences)
      ..sort((a, b) => (b.snoozedUntil ?? b.scheduledAt).compareTo(a.snoozedUntil ?? a.scheduledAt));

    return sorted.where((occ) {
      // 1. Status Filter (excluding pending from history)
      // Note: Only completed/actioned doses or past missed doses are shown in history.
      if (occ.status == 'pending') {
        return false;
      }
      
      if (statusFilter != 'all' && occ.status != statusFilter) {
        return false;
      }

      // 2. Date Filter
      if (selectedDate != null) {
        final startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        final endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59, 999);
        final occTime = occ.snoozedUntil ?? occ.scheduledAt;
        if (occTime.isBefore(startOfDay) || occTime.isAfter(endOfDay)) {
          return false;
        }
      }

      // 3. Search Query Filter
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final medicine = medicines[occ.medicineId];
        if (medicine == null) {
          return occ.dose.toLowerCase().contains(query) ||
              occ.foodInstruction.toLowerCase().contains(query);
        }
        return medicine.name.toLowerCase().contains(query) ||
            medicine.description.toLowerCase().contains(query) ||
            medicine.type.toLowerCase().contains(query) ||
            occ.dose.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  HistoryState copyWith({
    String? searchQuery,
    String? statusFilter,
    DateTime? Function()? selectedDate,
    List<DoseOccurrenceModel>? occurrences,
    Map<String, MedicineModel>? medicines,
    HistoryStatus? status,
    String? errorMessage,
  }) {
    return HistoryState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedDate: selectedDate != null ? selectedDate() : this.selectedDate,
      occurrences: occurrences ?? this.occurrences,
      medicines: medicines ?? this.medicines,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        statusFilter,
        selectedDate,
        occurrences,
        medicines,
        status,
        errorMessage,
      ];
}
