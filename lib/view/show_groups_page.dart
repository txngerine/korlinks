// ignore_for_file: sort_child_properties_last, unnecessary_null_comparison, use_build_context_synchronously, prefer_const_constructors, use_super_parameters

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/group_controller.dart';
import '../model/groupmodel.dart';

class ShowGroupsPage extends StatefulWidget {
  const ShowGroupsPage({Key? key}) : super(key: key);

  @override
  State<ShowGroupsPage> createState() => _ShowGroupsPageState();
}

class _ShowGroupsPageState extends State<ShowGroupsPage> {
  final GroupController groupController = Get.find<GroupController>();
  late Future<void> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = groupController.fetchGroups();
  }

  Future<void> _refreshGroups() async {
    await groupController.fetchGroups();
  }

  Future<void> _editGroup(Group group) async {
    final controller = TextEditingController(text: group.name);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final updatedGroupName = controller.text.trim();
              if (updatedGroupName.isNotEmpty) {
                await groupController.updateGroup(
                  group.id,
                  updatedGroupName,
                  group.members,
                );
                Get.snackbar('Success', 'Group name updated successfully!');
                await _refreshGroups();
                Navigator.pop(context);
              } else {
                Get.snackbar('Error', 'Group name cannot be empty');
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUri(String scheme, String phone) async {
    final uri = Uri.parse('$scheme$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Could not launch $scheme$phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: FutureBuilder(
        future: _groupsFuture,
        builder: (context, snapshot) {
          return Obx(() {
            final groups = groupController.groups;
            if (groups.isEmpty) {
              return const Center(child: Text('No groups found.'));
            }

            return RefreshIndicator(
              onRefresh: _refreshGroups,
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final members = group.members;

                  return ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        (group.name ?? 'G')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      group.name ?? 'Unnamed Group',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Members: ${members.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editGroup(group),
                        ),
                        IconButton(
  icon: Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Cancel deletion
              },
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Confirm deletion
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      groupController.deleteGroup(group.id); 
      Get.snackbar(
        'Contact Deleted',
        '${group.name} has been deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  },
),
                      ],
                    ),
                    children: [
                      ...members.map((member) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                (member.name ?? 'A')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              member.name ?? 'Unnamed Member',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(member.phone ?? 'No phone number'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () {
                                    if (member.phone != null) {
                                      _launchUri('tel:', member.phone!);
                                    } else {
                                      Get.snackbar('Error', 'Phone number not available');
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.blue),
                                  onPressed: () {
                                    if (member.phone != null) {
                                      _launchUri('sms:', member.phone!);
                                    } else {
                                      Get.snackbar('Error', 'Phone number not available');
                                    }
                                  },
                                ),
                              ],
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                final phones = members
                                    .where((m) => m.phone != null)
                                    .map((m) => m.phone!)
                                    .join(',');
                                if (phones.isNotEmpty) {
                                  _launchUri('tel:', phones);
                                } else {
                                  Get.snackbar('Error', 'No phone numbers available for group call');
                                }
                              },
                              icon: const Icon(Icons.call, color: Colors.white),
                              label: const Text('Group Call'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final phones = members
                                    .where((m) => m.phone != null)
                                    .map((m) => m.phone!)
                                    .join(';');
                                if (phones.isNotEmpty) {
                                  _launchUri('sms:', phones);
                                } else {
                                  Get.snackbar('Error', 'No phone numbers available for group message');
                                }
                              },
                              icon: const Icon(Icons.message, color: Colors.white),
                              label: const Text('Group Message'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          });
        },
      ),
    );
  }
}
