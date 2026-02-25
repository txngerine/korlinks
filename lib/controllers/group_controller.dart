import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/groupmodel.dart';
import '../model/contact.dart';

class GroupController extends GetxController {
  final String _boxName = 'groups';
  RxList<Group> groups = <Group>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchGroups();
  }

  Future<void> createGroup(String groupName, List<Contact> members) async {
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    final group = Group(
      id: groupId,
      name: groupName,
      members: members,
      createdAt: DateTime.now(),
    );

    try {
      final box = await Hive.openBox<Group>(_boxName);
      await box.put(groupId, group);
      groups.add(group);
      Get.snackbar('Success', 'Group "$groupName" created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create group: $e');
    }
  }

  Future<void> updateGroup(String groupId, String newGroupName, List<Contact> newMembers) async {
    try {
      final box = await Hive.openBox<Group>(_boxName);
      final group = box.get(groupId);

      if (group != null) {
        final updatedGroup = Group(
          id: group.id,
          name: newGroupName,
          members: newMembers,
          createdAt: group.createdAt,
          updatedAt: DateTime.now(),
        );

        await box.put(groupId, updatedGroup);

        final index = groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          groups[index] = updatedGroup;
        }

        Get.snackbar('Success', 'Group "$newGroupName" updated successfully!');
      } else {
        Get.snackbar('Error', 'Group not found!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final box = await Hive.openBox<Group>(_boxName);
      await box.delete(groupId);
      groups.removeWhere((g) => g.id == groupId);
      Get.snackbar('Success', 'Group deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete group: $e');
    }
  }

  Future<void> fetchGroups() async {
    try {
      final box = await Hive.openBox<Group>(_boxName);
      groups.value = box.values.toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch groups: $e');
    }
  }

  Future<void> addContactsToGroup(String groupId, List<Contact> newContacts) async {
    try {
      final box = await Hive.openBox<Group>(_boxName);
      final group = box.get(groupId);

      if (group != null) {
        final updatedMembers = List<Contact>.from(group.members)..addAll(newContacts);
        final updatedGroup = Group(
          id: group.id,
          name: group.name,
          members: updatedMembers,
          createdAt: group.createdAt,
          updatedAt: DateTime.now(),
        );

        await box.put(groupId, updatedGroup);

        final index = groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          groups[index] = updatedGroup;
        }

        Get.snackbar('Success', 'Contacts added to group "${group.name}" successfully!');
      } else {
        Get.snackbar('Error', 'Group not found!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add contacts: $e');
    }
  }
}
