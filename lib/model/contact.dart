import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 0)
class Contact extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? landline;

  @HiveField(4)
  String email;

  @HiveField(5)
  String ownerId;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  List<String> phoneNumbers;

  @HiveField(8)
  List<String> landlineNumbers;

  @HiveField(9)
  List<String> emailAddresses;

  @HiveField(10)
  Map<String, String> customFields;

  @HiveField(11)
  String? whatsapp;

  @HiveField(12)
  String? facebook;

  @HiveField(13)
  String? instagram;

  @HiveField(14)
  String? youtube;

  @HiveField(15)
  bool isSynced;

  @HiveField(16)
  String? website;

  @HiveField(17)
  String? xcom; // 👈 NEW FIELD for x.com URL or username

  @HiveField(18)
  bool importedFromCsv; // 👈 NEW FIELD

  @HiveField(19)
  bool isDeleted; // 👈 RECYCLE BIN FLAG

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.landline,
    required this.email,
    required this.ownerId,
    required this.isFavorite,
    required this.phoneNumbers,
    required this.landlineNumbers,
    required this.emailAddresses,
    required this.customFields,
    this.whatsapp,
    this.facebook,
    this.instagram,
    this.youtube,
    this.website,
    this.isSynced = true,
    this.xcom,
    this.importedFromCsv = false, // 👈 default false
    this.isDeleted = false, // 👈 default not deleted
  });

  factory Contact.fromMap(String id, Map<String, dynamic> map) {
    return Contact(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      landline: map['landline'],
      email: map['email'] ?? '',
      ownerId: map['ownerId'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
      landlineNumbers: List<String>.from(map['landlineNumbers'] ?? []),
      emailAddresses: List<String>.from(map['emailAddresses'] ?? []),
      customFields: Map<String, String>.from(map['customFields'] ?? {}),
      whatsapp: map['whatsapp'],
      facebook: map['facebook'],
      instagram: map['instagram'],
      youtube: map['youtube'],
      website: map['website'],
      xcom: map['xcom'],
      isSynced: map['isSynced'] ?? true,
      importedFromCsv: map['importedFromCsv'] ?? false, // 👈 load flag
      isDeleted: map['isDeleted'] ?? false, // 👈 load deleted flag
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'landline': landline,
      'email': email,
      'ownerId': ownerId,
      'isFavorite': isFavorite,
      'phoneNumbers': phoneNumbers,
      'landlineNumbers': landlineNumbers,
      'emailAddresses': emailAddresses,
      'customFields': customFields,
      'whatsapp': whatsapp,
      'facebook': facebook,
      'instagram': instagram,
      'youtube': youtube,
      'website': website,
      'xcom': xcom,
      'isSynced': isSynced,
      'importedFromCsv': importedFromCsv, // 👈 save flag
      'isDeleted': isDeleted, // 👈 save deleted flag
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? landline,
    String? email,
    String? ownerId,
    bool? isFavorite,
    List<String>? phoneNumbers,
    List<String>? landlineNumbers,
    List<String>? emailAddresses,
    Map<String, String>? customFields,
    String? whatsapp,
    String? facebook,
    String? instagram,
    String? youtube,
    String? website,
    String? xcom,
    bool? isSynced,
    bool? importedFromCsv,
    bool? isDeleted,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      landline: landline ?? this.landline,
      email: email ?? this.email,
      ownerId: ownerId ?? this.ownerId,
      isFavorite: isFavorite ?? this.isFavorite,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      landlineNumbers: landlineNumbers ?? this.landlineNumbers,
      emailAddresses: emailAddresses ?? this.emailAddresses,
      customFields: customFields ?? this.customFields,
      whatsapp: whatsapp ?? this.whatsapp,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      website: website ?? this.website,
      xcom: xcom ?? this.xcom,
      isSynced: isSynced ?? this.isSynced,
      importedFromCsv: importedFromCsv ?? this.importedFromCsv, // 👈 keep flag
      isDeleted: isDeleted ?? this.isDeleted, // 👈 keep deleted flag
    );
  }
}
