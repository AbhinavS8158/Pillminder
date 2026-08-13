import 'package:equatable/equatable.dart';
import '../../../../core/models/dose_occurrence_model.dart';
import '../../../../core/models/medicine_model.dart';

abstract class ReminderState extends Equatable {
  const ReminderState();

  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class ReminderActive extends ReminderState {
  final DoseOccurrenceModel occurrence;
  final MedicineModel medicine;

  const ReminderActive({
    required this.occurrence,
    required this.medicine,
  });

  @override
  List<Object?> get props => [occurrence, medicine];
}

class ReminderSuccess extends ReminderState {
  final String message;

  const ReminderSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReminderError extends ReminderState {
  final String message;

  const ReminderError(this.message);

  @override
  List<Object?> get props => [message];
}
