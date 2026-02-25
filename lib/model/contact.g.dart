// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 0;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      landline: fields[3] as String?,
      email: fields[4] as String,
      ownerId: fields[5] as String,
      isFavorite: fields[6] as bool,
      phoneNumbers: (fields[7] as List).cast<String>(),
      landlineNumbers: (fields[8] as List).cast<String>(),
      emailAddresses: (fields[9] as List).cast<String>(),
      customFields: (fields[10] as Map).cast<String, String>(),
      whatsapp: fields[11] as String?,
      facebook: fields[12] as String?,
      instagram: fields[13] as String?,
      youtube: fields[14] as String?,
      website: fields[16] as String?,
      isSynced: fields[15] as bool,
      importedFromCsv: fields[17] as bool,
      isDeleted: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.landline)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.ownerId)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.phoneNumbers)
      ..writeByte(8)
      ..write(obj.landlineNumbers)
      ..writeByte(9)
      ..write(obj.emailAddresses)
      ..writeByte(10)
      ..write(obj.customFields)
      ..writeByte(11)
      ..write(obj.whatsapp)
      ..writeByte(12)
      ..write(obj.facebook)
      ..writeByte(13)
      ..write(obj.instagram)
      ..writeByte(14)
      ..write(obj.youtube)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.website)
      ..writeByte(17)
      ..write(obj.importedFromCsv)
      ..writeByte(18)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
