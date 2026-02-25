// // ignore_for_file: unused_local_variable

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/contact_controller.dart';
// import '../controllers/contact_import.dart';

// class ContactImportView extends StatelessWidget {
//   final ContactImportController importController =
//       Get.put(ContactImportController());
//   final ContactController contactController = Get.find<ContactController>();

//   // Set to hold the selected contact indices
//   final RxSet<int> selectedContacts = <int>{}.obs;

//   @override
//   Widget build(BuildContext context) {
//     importController.fetchDeviceContacts();

//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           // "Select All" checkbox
//           Obx(() {
//             return importController.deviceContacts.isNotEmpty
//                 ? Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Row(
//                       children: [
//                         Checkbox(
//                           value: selectedContacts.length ==
//                               importController.deviceContacts.length,
//                           onChanged: (bool? value) {
//                             if (value == true) {
//                               // Select all contacts
//                               selectedContacts.addAll(
//                                 List.generate(
//                                     importController.deviceContacts.length,
//                                     (index) => index),
//                               );
//                             } else {
//                               // Deselect all contacts
//                               selectedContacts.clear();
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   )
//                 : SizedBox.shrink();
//           }),

//           // Import TextButton
//           Obx(() {
//             return selectedContacts.isNotEmpty
//                 ? TextButton(
//                     onPressed: () {
//                       // Import all selected contacts
//                       int selectedCount = selectedContacts.length;
//                       for (final index in selectedContacts) {
//                         final contact = importController.deviceContacts[index];
//                         contact.ownerId = contactController
//                             .authController.firebaseUser.value!.uid;
//                         contactController.addContact(contact);
//                       }
//                       // Clear the selection and show success message
//                       selectedContacts.clear();

//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             '$selectedCount contacts imported successfully.',
//                           ),
//                           behavior: SnackBarBehavior.floating,
//                         ),
//                       );
//                       Navigator.pop(context);
//                     },
//                     child: Text(
//                       'Import',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                   )
//                 : SizedBox.shrink();
//           }),
//         ],
//       ),
//       body: Obx(() {
//         if (importController.deviceContacts.isEmpty) {
//           return Center(child: CircularProgressIndicator());
//         }

//         return ListView.builder(
//           itemCount: importController.deviceContacts.length,
//           itemBuilder: (context, index) {
//             final contact = importController.deviceContacts[index];

//             return ListTile(
//               leading: CircleAvatar(
//                   child: Text(contact.name[0].toUpperCase())),
//               title: Text(contact.name),
//               subtitle: Text(contact.phone.isNotEmpty
//                   ? contact.phone
//                   : 'No phone number'),
//               trailing: Obx(() {
//                 final isSelected = selectedContacts.contains(index);
//                 return Checkbox(
//                   value: isSelected,
//                   onChanged: (bool? value) {
//                     if (value == true) {
//                       selectedContacts.add(index);
//                     } else {
//                       selectedContacts.remove(index);
//                     }
//                   },
//                 );
//               }),
//             );
//           },
//         );
//       }),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contact_controller.dart';
import '../controllers/contact_import.dart';

class ContactImportView extends StatelessWidget {
  final ContactImportController importController = Get.put(ContactImportController());
  final ContactController contactController = Get.find<ContactController>();
  final RxSet<int> selectedContacts = <int>{}.obs;

  ContactImportView({super.key}) {
    // Fetch device contacts once when view is created
    importController.fetchDeviceContacts();
  }

  void importSelectedContacts(BuildContext context) {
    final count = selectedContacts.length;
    for (final index in selectedContacts) {
      final contact = importController.deviceContacts[index];
      contact.ownerId = contactController.authController.firebaseUser.value!.uid;
      contactController.addContact(contact);
    }
    selectedContacts.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count contacts imported successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Contacts', style: TextStyle(color: Colors.black)),
        actions: [
          // Select All
          Obx(() {
            final contacts = importController.deviceContacts;
            if (contacts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Checkbox(
                value: selectedContacts.length == contacts.length,
                onChanged: (value) {
                  if (value == true) {
                    selectedContacts.addAll(List.generate(contacts.length, (i) => i));
                  } else {
                    selectedContacts.clear();
                  }
                },
              ),
            );
          }),

          // Import Button
          Obx(() {
            if (selectedContacts.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => importSelectedContacts(context),
              child: const Text('Import', style: TextStyle(color: Colors.black)),
            );
          }),
        ],
      ),
      body: Obx(() {
        final contacts = importController.deviceContacts;
        if (contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final isSelected = selectedContacts.contains(index);

            return ListTile(
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
              ),
            );
          },
        );
      }),
    );
  }
}
