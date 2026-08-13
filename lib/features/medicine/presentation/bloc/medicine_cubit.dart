import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/medicine_model.dart';
import '../../../../core/repositories/medicine_repository.dart';
import 'medicine_state.dart';

class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository repository;

  MedicineCubit(this.repository) : super(MedicineInitial());

  Future<void> addMedicine(MedicineModel medicine) async {
    emit(MedicineLoading());
    try {
      await repository.addMedicine(medicine);
      await repository.syncOngoingOccurrences();
      emit(MedicineSuccess());
    } catch (e) {
      emit(MedicineError(e.toString()));
    }
  }

  Future<void> editMedicine(MedicineModel medicine) async {
    emit(MedicineLoading());
    try {
      await repository.editMedicine(medicine);
      await repository.syncOngoingOccurrences();
      emit(MedicineSuccess());
    } catch (e) {
      emit(MedicineError(e.toString()));
    }
  }

  Future<void> deleteMedicine(String id) async {
    emit(MedicineLoading());
    try {
      await repository.deleteMedicine(id);
      emit(MedicineSuccess());
    } catch (e) {
      emit(MedicineError(e.toString()));
    }
  }

  Future<void> pauseMedicine(String id) async {
    emit(MedicineLoading());
    try {
      await repository.pauseMedicine(id);
      emit(MedicineSuccess());
    } catch (e) {
      emit(MedicineError(e.toString()));
    }
  }

  Future<void> resumeMedicine(String id) async {
    emit(MedicineLoading());
    try {
      await repository.resumeMedicine(id);
      await repository.syncOngoingOccurrences();
      emit(MedicineSuccess());
    } catch (e) {
      emit(MedicineError(e.toString()));
    }
  }
}
