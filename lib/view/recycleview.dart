// ignore_for_file: prefer_const_constructors, unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contact_controller.dart';
import '../model/contact.dart';

class RecycleBinView extends StatelessWidget {
  final ContactController contactController = Get.find<ContactController>();

  RecycleBinView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recycle Bin',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        final deletedContacts = contactController.deletedContacts;
        if (deletedContacts.isEmpty) {
          return Center(child: Text('No deleted contacts.'));
        }
        return ListView.builder(
          itemCount: deletedContacts.length,
          itemBuilder: (context, index) {
            final contact = deletedContacts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(contact.name),
                subtitle: Text(contact.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.restore, color: Colors.green),
                      tooltip: 'Restore',
                      onPressed: () {
                        contactController.restoreContact(contact);
                        Get.snackbar('Restored', '${contact.name} restored.');
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.grey),
                      tooltip: 'Delete Permanently',
                      onPressed: () async {
                        await contactController.permanentlyDeleteContact(contact);
                        Get.snackbar('Deleted', '${contact.name} permanently deleted.');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}