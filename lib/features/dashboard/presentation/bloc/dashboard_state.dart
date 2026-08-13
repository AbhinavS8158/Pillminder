import 'package:equatable/equatable.dart';
import '../../../../core/models/dose_occurrence_model.dart';
import '../../../../core/models/medicine_model.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DateTime selectedDate;
  final String searchQuery;
  final List<DoseOccurrenceModel> occurrences;
  final Map<String, MedicineModel> medicines;
  final DashboardStatus status;
  final String errorMessage;

  const DashboardState({
    required this.selectedDate,
    required this.searchQuery,
    required this.occurrences,
    required this.medicines,
    required this.status,
    required this.errorMessage,
  });

  factory DashboardState.initial() {
    return DashboardState(
      selectedDate: DateTime.now(),
      searchQuery: '',
      occurrences: const [],
      medicines: const {},
      status: DashboardStatus.initial,
      errorMessage: '',
    );
  }

  int get totalDoses => occurrences.length;
  int get takenDoses => occurrences.where((o) => o.status == 'taken').length;
  int get pendingDoses => occurrences.where((o) => o.status == 'pending').length;
  int get missedDoses => occurrences.where((o) => o.status == 'missed').length;
  int get skippedDoses => occurrences.where((o) => o.status == 'skipped').length;

  List<DoseOccurrenceModel> get filteredOccurrences {
    // Sort occurrences by time
    final sorted = List<DoseOccurrenceModel>.from(occurrences)
      ..sort((a, b) => (a.snoozedUntil ?? a.scheduledAt).compareTo(b.snoozedUntil ?? b.scheduledAt));

    if (searchQuery.trim().isEmpty) {
      return sorted;
    }
    final query = searchQuery.toLowerCase();
    return sorted.where((occ) {
      final medicine = medicines[occ.medicineId];
      if (medicine == null) return false;
      return medicine.name.toLowerCase().contains(query) ||
          medicine.description.toLowerCase().contains(query) ||
          medicine.type.toLowerCase().contains(query);
    }).toList();
  }

  DashboardState copyWith({
    DateTime? selectedDate,
    String? searchQuery,
    List<DoseOccurrenceModel>? occurrences,
    Map<String, MedicineModel>? medicines,
    DashboardStatus? status,
    String? errorMessage,
  }) {
    return DashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
      occurrences: occurrences ?? this.occurrences,
      medicines: medicines ?? this.medicines,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedDate,
        searchQuery,
        occurrences,
        medicines,
        status,
        errorMessage,
      ];
}
