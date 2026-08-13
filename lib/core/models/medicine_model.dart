import 'package:hive/hive.dart';
import 'dose_model.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 0)
class MedicineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String type; // Tablet, Capsule, Syrup, Injection, etc.

  @HiveField(4)
  final String strength; // e.g. 500 mg

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime? endDate;

  @HiveField(7)
  final List<DoseModel> doses;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  MedicineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.strength,
    required this.startDate,
    this.endDate,
    required this.doses,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicineModel copyWith({
    String? name,
    String? description,
    String? type,
    String? strength,
    DateTime? startDate,
    DateTime? Function()? endDate,
    List<DoseModel>? doses,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      strength: strength ?? this.strength,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      doses: doses ?? this.doses,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
