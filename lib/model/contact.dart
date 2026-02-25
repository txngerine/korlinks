


// import 'package:hive/hive.dart';

// part 'contact.g.dart';

// @HiveType(typeId: 0)
// class Contact extends HiveObject {
//   @HiveField(0)
//   String id;

//   @HiveField(1)
//   String name;

//   @HiveField(2)
//   String phone;

//   @HiveField(3)
//   String? landline;

//   @HiveField(4)
//   String email;

//   @HiveField(5)
//   String ownerId;

//   @HiveField(6)
//   bool isFavorite;

//   @HiveField(7)
//   List<String> phoneNumbers;

//   @HiveField(8)
//   List<String> landlineNumbers;

//   @HiveField(9)
//   List<String> emailAddresses;

//   @HiveField(10)
//   Map<String, String> customFields;

//   @HiveField(11)
//   String? whatsapp;

//   @HiveField(12)
//   String? facebook;

//   @HiveField(13)
//   String? instagram;

//   @HiveField(14)
//   String? youtube;

//   @HiveField(15)
//   bool isSynced;

//   @HiveField(16)
//   String? website; // 1. Add this line
//   @HiveField(17)
//   bool importedFromCsv;


//   Contact({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.landline,
//     required this.email,
//     required this.ownerId,
//     required this.isFavorite,
//     required this.phoneNumbers,
//     required this.landlineNumbers,
//     required this.emailAddresses,
//     required this.customFields,
//     this.whatsapp,
//     this.facebook,
//     this.instagram,
//     this.youtube,
//     this.website, // 2. Add this line
//     this.isSynced = true,this.importedFromCsv = false,
//   });

//   factory Contact.fromMap(String id, Map<String, dynamic> map) {
//     return Contact(
//       id: id,
//       name: map['name'] ?? '',
//       phone: map['phone'] ?? '',
//       landline: map['landline'],
//       email: map['email'] ?? '',
//       ownerId: map['ownerId'] ?? '',
//       isFavorite: map['isFavorite'] ?? false,
//       phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
//       landlineNumbers: List<String>.from(map['landlineNumbers'] ?? []),
//       emailAddresses: List<String>.from(map['emailAddresses'] ?? []),
//       customFields: Map<String, String>.from(map['customFields'] ?? {}),
//       whatsapp: map['whatsapp'],
//       facebook: map['facebook'],
//       instagram: map['instagram'],
//       youtube: map['youtube'],
//       website: map['website'], // 3. Add this line
//       isSynced: map['isSynced'] ?? true,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'phone': phone,
//       'landline': landline,
//       'email': email,
//       'ownerId': ownerId,
//       'isFavorite': isFavorite,
//       'phoneNumbers': phoneNumbers,
//       'landlineNumbers': landlineNumbers,
//       'emailAddresses': emailAddresses,
//       'customFields': customFields,
//       'whatsapp': whatsapp,
//       'facebook': facebook,
//       'instagram': instagram,
//       'youtube': youtube,
//       'website': website, // 4. Add this line
//       'isSynced': true,
//     };
//   }

//   Contact copyWith({
//     String? id,
//     String? name,
//     String? phone,
//     String? landline,
//     String? email,
//     String? ownerId,
//     bool? isFavorite,
//     List<String>? phoneNumbers,
//     List<String>? landlineNumbers,
//     List<String>? emailAddresses,
//     Map<String, String>? customFields,
//     String? whatsapp,
//     String? facebook,
//     String? instagram,
//     String? youtube,
//     String? website, // 5. Add this line
//     bool? isSynced,
//   }) {
//     return Contact(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       phone: phone ?? this.phone,
//       landline: landline ?? this.landline,
//       email: email ?? this.email,
//       ownerId: ownerId ?? this.ownerId,
//       isFavorite: isFavorite ?? this.isFavorite,
//       phoneNumbers: phoneNumbers ?? this.phoneNumbers,
//       landlineNumbers: landlineNumbers ?? this.landlineNumbers,
//       emailAddresses: emailAddresses ?? this.emailAddresses,
//       customFields: customFields ?? this.customFields,
//       whatsapp: whatsapp ?? this.whatsapp,
//       facebook: facebook ?? this.facebook,
//       instagram: instagram ?? this.instagram,
//       youtube: youtube ?? this.youtube,
//       website: website ?? this.website, // 6. Add this line
//       isSynced: isSynced ?? this.isSynced,
//     );
//   }
// }


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
  bool importedFromCsv; // 👈 NEW FIELD

  @HiveField(18)
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
      isSynced: isSynced ?? this.isSynced,
      importedFromCsv: importedFromCsv ?? this.importedFromCsv, // 👈 keep flag
      isDeleted: isDeleted ?? this.isDeleted, // 👈 keep deleted flag
    );
  }
}
