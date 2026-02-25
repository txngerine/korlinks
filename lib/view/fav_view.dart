import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/contact_controller.dart';
import 'contact_detail.dart';

class FavoriteContactsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ContactController controller = Get.find<ContactController>();

    return Obx(() {
      // Set to track unique contacts by name and phone
      final seen = <String>{};

      // Filter, remove duplicates, and sort favorite contacts
      final favoriteContacts = controller.contacts
          .where((contact) => contact.isFavorite)
          .where((contact) =>
              seen.add('${contact.name.toLowerCase()}|${contact.phone}'))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Show message if there are no favorites
      if (favoriteContacts.isEmpty) {
        return Center(
          child: Text('No favorite contacts found.'),
        );
      }

      // ListView for favorite contacts
      return ListView.builder(
        itemCount: favoriteContacts.length,
        itemBuilder: (context, index) {
          final contact = favoriteContacts[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(contact.name[0].toUpperCase()),
            ),
            title: Text(contact.name),
            subtitle: Text(contact.phone),
            trailing: IconButton(
              tooltip: 'Remove from favorites',
              icon: Icon(Icons.favorite, color: Colors.red),
              onPressed: () => controller.toggleFavorite(contact),
            ),
            onTap: () => Get.to(() => ContactDetailView(contact: contact)),
          );
        },
      );
    });
  }
}
