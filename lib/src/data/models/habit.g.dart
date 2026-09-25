// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawDays = fields[7];
    final repeatDays = rawDays is List
        ? List<bool>.generate(
            7,
            (i) => i < rawDays.length ? _hbBool(rawDays[i], false) : false,
          )
        : List<bool>.filled(7, false);
    return Habit(
      id: fields[0]?.toString() ?? '',
      name: fields[1]?.toString() ?? '',
      category: fields[2]?.toString() ?? 'Other',
      colorIndex: _hbInt(fields[3], 0),
      iconName: fields[4]?.toString() ?? 'star',
      reminderEnabled: _hbBool(fields[5], false),
      reminderTime: _hbDateOrNull(fields[6]),
      repeatDays: repeatDays,
      createdAt: _hbDate(fields[8], DateTime.now()),
      isArchived: _hbBool(fields[9], false),
      notificationId: _hbInt(fields[10], 0),
      frequencyPerDay: _hbInt(fields[11], 1),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.colorIndex)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.reminderEnabled)
      ..writeByte(6)
      ..write(obj.reminderTime)
      ..writeByte(7)
      ..write(obj.repeatDays)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isArchived)
      ..writeByte(10)
      ..write(obj.notificationId)
      ..writeByte(11)
      ..write(obj.frequencyPerDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
