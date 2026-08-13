// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoseModelAdapter extends TypeAdapter<DoseModel> {
  @override
  final int typeId = 1;

  @override
  DoseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoseModel(
      id: fields[0] as String,
      time: fields[1] as String,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      foodInstruction: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoseModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.foodInstruction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
