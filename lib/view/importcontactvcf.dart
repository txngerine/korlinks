

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contact_controller.dart';
import '../controllers/contact_import.dart';


class ContactImportFromVcfView extends StatelessWidget {
  ContactImportFromVcfView({super.key});

  final ContactImportController importController = Get.put(ContactImportController());
  final ContactController contactController = Get.find<ContactController>();
  final RxSet<int> selectedContacts = <int>{}.obs;

  void importSelectedContacts(BuildContext context) async {
    final count = selectedContacts.length;
    final user = contactController.authController.firebaseUser.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      for (final index in selectedContacts) {
        final contact = importController.importedContacts[index];
        contact.ownerId = user.uid;
        await contactController.addContact(contact);
      }
      selectedContacts.clear();
      Navigator.pop(context);
      // Show snackbar after pop
      Future.delayed(const Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count contacts imported successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import contacts: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importFromVcf(BuildContext context) async {
    importController.importedContacts.clear();
    selectedContacts.clear();
    try {
      await importController.importContactsFromVcfFile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import VCF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importFromCsv(BuildContext context) async {
    importController.importedContacts.clear();
    selectedContacts.clear();
    try {
      await importController.importContactsFromCsvFile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import CSV: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imported Contacts', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Obx(() {
            final contacts = importController.importedContacts;
            if (contacts.isEmpty) return const SizedBox.shrink();
            final allSelected = contacts.isNotEmpty && selectedContacts.length == contacts.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select All Checkbox
                Checkbox(
                  value: allSelected,
                  onChanged: (value) {
                    if (value == true) {
                      selectedContacts.clear();
                      selectedContacts.addAll(List.generate(contacts.length, (i) => i));
                    } else {
                      selectedContacts.clear();
                    }
                  },
                  checkColor: Colors.black,
                  fillColor: MaterialStateProperty.all(Colors.yellow.shade700),
                ),
                // Import Button
                if (selectedContacts.isNotEmpty)
                  TextButton(
                    onPressed: () => importSelectedContacts(context),
                    child: const Text('Import', style: TextStyle(color: Colors.black)),
                  ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Import Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _importFromVcf(context),
                  icon: const Icon(Icons.file_open),
                  label: const Text('Select VCF File', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _importFromCsv(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Select CSV File', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),

          // Contact List
          Expanded(
            child: Obx(() {
              final contacts = importController.importedContacts;
              if (contacts.isEmpty) return const Center(child: Text('No contacts loaded.'));
              return ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isSelected = selectedContacts.contains(index);
                  return Container(
                    color: isSelected ? Colors.yellow[100] : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone.isNotEmpty ? contact.phone : 'No phone number'),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          if (value == true) {
                            selectedContacts.add(index);
                          } else {
                            selectedContacts.remove(index);
                          }
                        },
                        checkColor: Colors.black, // tick color
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.yellow.shade700; // background when checked
                          }
                          return Colors.grey.shade200; // background when unchecked
                        }),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
