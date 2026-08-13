// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_occurrence_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoseOccurrenceModelAdapter extends TypeAdapter<DoseOccurrenceModel> {
  @override
  final int typeId = 2;

  @override
  DoseOccurrenceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoseOccurrenceModel(
      id: fields[0] as String,
      medicineId: fields[1] as String,
      doseId: fields[2] as String,
      scheduledAt: fields[3] as DateTime,
      dose: fields[4] as String,
      foodInstruction: fields[5] as String,
      status: fields[6] as String,
      actionAt: fields[7] as DateTime?,
      snoozedUntil: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DoseOccurrenceModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineId)
      ..writeByte(2)
      ..write(obj.doseId)
      ..writeByte(3)
      ..write(obj.scheduledAt)
      ..writeByte(4)
      ..write(obj.dose)
      ..writeByte(5)
      ..write(obj.foodInstruction)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.actionAt)
      ..writeByte(8)
      ..write(obj.snoozedUntil)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseOccurrenceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
