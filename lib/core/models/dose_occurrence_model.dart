import 'package:hive/hive.dart';

part 'dose_occurrence_model.g.dart';

@HiveType(typeId: 2)
class DoseOccurrenceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicineId;

  @HiveField(2)
  final String doseId;

  @HiveField(3)
  final DateTime scheduledAt;

  @HiveField(4)
  final String dose; // snapshot of quantity + unit (e.g. "1 Tablet")

  @HiveField(5)
  final String foodInstruction; // snapshot of instruction

  @HiveField(6)
  final String status; // pending, taken, missed, skipped

  @HiveField(7)
  final DateTime? actionAt;

  @HiveField(8)
  final DateTime? snoozedUntil;

  @HiveField(9)
  final DateTime createdAt;

  DoseOccurrenceModel({
    required this.id,
    required this.medicineId,
    required this.doseId,
    required this.scheduledAt,
    required this.dose,
    required this.foodInstruction,
    required this.status,
    this.actionAt,
    this.snoozedUntil,
    required this.createdAt,
  });

  DoseOccurrenceModel copyWith({
    String? status,
    DateTime? actionAt,
    DateTime? Function()? snoozedUntil,
  }) {
    return DoseOccurrenceModel(
      id: id,
      medicineId: medicineId,
      doseId: doseId,
      scheduledAt: scheduledAt,
      dose: dose,
      foodInstruction: foodInstruction,
      status: status ?? this.status,
      actionAt: actionAt ?? this.actionAt,
      snoozedUntil: snoozedUntil != null ? snoozedUntil() : this.snoozedUntil,
      createdAt: createdAt,
    );
  }
}
