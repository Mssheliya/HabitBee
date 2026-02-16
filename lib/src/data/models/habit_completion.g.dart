// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitCompletionAdapter extends TypeAdapter<HabitCompletion> {
  @override
  final int typeId = 1;

  @override
  HabitCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitCompletion(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      completed: fields[3] as bool,
      completedAt: fields[4] as DateTime?,
      completionCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HabitCompletion obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.completionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
