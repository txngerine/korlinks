// import 'package:hive/hive.dart';
// import 'contact.dart';

// part 'groupmodel.g.dart';

// @HiveType(typeId: 1)
// class Group {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String name;

//   @HiveField(2)
//   final List<Contact> members;

//   @HiveField(3)
//   final DateTime createdAt;

//   @HiveField(4)
//   final DateTime? updatedAt;

//   Group({
//     required this.id,
//     required this.name,
//     required this.members,
//     required this.createdAt,
//     this.updatedAt,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'members': members.map((m) => m.toMap()).toList(),
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt?.toIso8601String(),
//     };
//   }

//   factory Group.fromMap(Map<String, dynamic> map) {
//     return Group(
//       id: map['id'] as String,
//       name: map['name'] as String,
//       members: List<Contact>.from(
//         (map['members'] as List).map((m) => Contact.fromMap(m['id'], m)),
//       ),
//       createdAt: DateTime.parse(map['createdAt']),
//       updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
//     );
//   }
// }



import 'package:hive/hive.dart';
import 'contact.dart';

part 'groupmodel.g.dart';

@HiveType(typeId: 1)
class Group extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Contact> members;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    final membersList = map['members'] as List? ?? [];

    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      members: membersList.map<Contact>((raw) {
        if (raw is Map<String, dynamic>) {
          final id = raw['id'] ?? '';
          return Contact.fromMap(id, raw);
        } else {
          throw Exception('Invalid member format in group: $raw');
        }
      }).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
