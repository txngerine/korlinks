import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contact_controller.dart';
import '../model/contact.dart';
import 'contact_detail.dart';

class GroupedContactsView extends StatelessWidget {
  final ContactController controller = Get.find<ContactController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grouped Contacts'),
        backgroundColor: Colors.blue,
      ),
      body: Obx(() {
        final contacts = controller.contacts;

        if (contacts.isEmpty) {
          return Center(
            child: Text(
              'No contacts available.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Group contacts alphabetically by the first letter of their name
        final Map<String, List<Contact>> groupedContacts = {};
        for (var contact in contacts) {
          final firstChar = contact.name[0].toUpperCase();
          groupedContacts.putIfAbsent(firstChar, () => []).add(contact);
        }

        // Sort group keys alphabetically
        final sortedKeys = groupedContacts.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final key = sortedKeys[index];
            final group = groupedContacts[key]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                // Grouped Contacts
                ...group.map((contact) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(contact.name[0].toUpperCase()),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    onTap: () {
                      // Navigate to contact details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactDetailView(contact: contact),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            );
          },
        );
      }),
    );
  }
}