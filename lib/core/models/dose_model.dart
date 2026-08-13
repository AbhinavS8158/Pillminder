import 'package:hive/hive.dart';

part 'dose_model.g.dart';

@HiveType(typeId: 1)
class DoseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String time; // HH:mm format

  @HiveField(2)
  final double quantity;

  @HiveField(3)
  final String unit;

  @HiveField(4)
  final String foodInstruction;

  DoseModel({
    required this.id,
    required this.time,
    required this.quantity,
    required this.unit,
    required this.foodInstruction,
  });
}
