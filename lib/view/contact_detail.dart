// ignore_for_file: prefer_const_constructors, avoid_print, library_private_types_in_public_api, use_build_context_synchronously, use_super_parameters, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/contact_controller.dart';
import '../controllers/auth_controller.dart';
import '../model/contact.dart';
import 'addeditpage.dart';

class OppoFixLauncher {
  static const MethodChannel platform =
      MethodChannel('com.codecarrots.korlinks/launcher');

  static Future<void> launchCustomURL(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await _launchIntentFallback(uri.toString());
      }
    } catch (e) {
      print('launchCustomURL error: $e');
      await _launchIntentFallback(uri.toString());
    }
  }

  static Future<void> _launchIntentFallback(String url) async {
    try {
      await platform.invokeMethod('launchUrl', {'url': url});
    } catch (e) {
      print('Fallback launch failed: $e');
    }
  }

  static Future<void> launchPhone(String phoneNumber) async {
    await launchCustomURL(Uri(scheme: 'tel', path: phoneNumber));
  }

  static Future<void> launchSMS(String phoneNumber) async {
    await launchCustomURL(Uri(scheme: 'sms', path: phoneNumber));
  }

  static Future<void> launchEmail(String email) async {
    await launchCustomURL(Uri(scheme: 'mailto', path: email));
  }

  static Future<void> launchFacebook(String? profileUrl) async {
    if (profileUrl == null || profileUrl.isEmpty) return;
    final id = Uri.parse(profileUrl).pathSegments.last;
    try {
      await platform.invokeMethod('launchFacebook', {'id': id});
    } catch (e) {
      print('Facebook intent failed: $e');
      await launchCustomURL(Uri.parse(profileUrl));
    }
  }

  static Future<void> launchInstagram(String? usernameOrUrl) async {
    if (usernameOrUrl == null || usernameOrUrl.isEmpty) return;

    String username;
    if (usernameOrUrl.startsWith('http')) {
      final uri = Uri.parse(usernameOrUrl);
      username = uri.pathSegments.first;
    } else {
      username = usernameOrUrl;
    }

    try {
      await platform.invokeMethod('launchInstagram', {'username': username});
    } catch (e) {
      print('Instagram intent failed: $e');
      await launchCustomURL(Uri.parse('https://www.instagram.com/$username'));
    }
  }

  static Future<void> launchYouTube(String? url) async {
    if (url == null || url.isEmpty) return;
    String videoId;

    try {
      Uri uri = Uri.parse(url);
      if (uri.host.contains("youtu.be")) {
        videoId = uri.pathSegments.last;
      } else if (uri.queryParameters.containsKey('v')) {
        videoId = uri.queryParameters['v']!;
      } else {
        videoId = url;
      }

      await platform.invokeMethod('launchYouTube', {'videoId': videoId});
    } catch (e) {
      print('YouTube intent failed: $e');
      await launchCustomURL(Uri.parse(url));
    }
  }

  static Future<void> launchWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    try {
      await platform.invokeMethod('launchWhatsApp', {'phone': phoneNumber});
    } catch (e) {
      print('WhatsApp intent failed: $e');
      await launchCustomURL(Uri.parse('https://wa.me/$phoneNumber'));
    }
  }
}

class ContactDetailView extends StatefulWidget {
  final Contact contact;

  const ContactDetailView({Key? key, required this.contact}) : super(key: key);

  @override
  _ContactDetailViewState createState() => _ContactDetailViewState();
}

class _ContactDetailViewState extends State<ContactDetailView> {
  late Contact contact;
  final authController = Get.find<AuthController>();
  final contactController = Get.find<ContactController>();

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  Future<void> _saveCustomFieldsToFirebase() async {
    try {
      final customFields = contact.customFields;
      if (customFields != null) {
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(contact.id)
            .update({'customFields': customFields});
        print('Custom fields saved to Firebase!');
      }
    } catch (e) {
      _showErrorDialog('Failed to save changes to Firebase: $e');
    }
  }

  Future<void> _deleteContact() async {
    final role = authController.userRole.value;
    try {
      if (role == 'admin') {
        await contactController.deleteContactFromFirebaseIfAdmin(contact);
        Get.snackbar('Success', 'Contact deleted from Firebase!');
        Navigator.pop(context);
      } else if (role == 'user' &&
          contact.ownerId == authController.firebaseUser.value?.uid) {
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(contact.id)
            .delete();
        Get.snackbar('Success', 'Contact deleted successfully!');
        Navigator.pop(context);
      } else {
        Get.snackbar(
            'Permission Denied', 'You can only delete your own contacts.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete contact: $e');
    }
  }

  Future<void> _confirmDeleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you really want to delete this contact?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',style: TextStyle(color: Colors.black),)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',style: TextStyle(color: Colors.red),)),
        ],
      ),
    );

    if (confirm ?? false) {
      await _deleteContact();
    }
  }

  void _shareContact() {
    final customFields = contact.customFields.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n') ??
        'No custom fields';
    final phoneNumbers =
        contact.phoneNumbers.join('\n') ?? 'No additional phone numbers';
    final emailAddresses =
        contact.emailAddresses.join('\n') ?? 'No additional email addresses';
    final landlineNumbers =
        contact.landlineNumbers.join('\n') ?? 'No additional landline numbers';

    Share.share('Contact Information:\n'
        'Name: ${contact.name}\n'
        'Phone: ${contact.phone}\n'
        'Landline: ${contact.landline}\n'
        'Email: ${contact.email}\n'
        'Facebook: ${contact.facebook}\n'
        'Instagram: ${contact.instagram}\n'
        'WhatsApp: ${contact.whatsapp}\n'
        'YouTube: ${contact.youtube}\n'
        'Additional Phone Numbers:\n$phoneNumbers\n'
        'Additional Email Addresses:\n$emailAddresses\n'
        'Additional Landline Numbers:\n$landlineNumbers\n'
        'Custom Fields:\n$customFields');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))
        ],
      ),
    );
  }

  void _showWhatsAppOptions(String whatsappNumber) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.message, color: Colors.green),
              title: Text('Message'),
              onTap: () {
                Navigator.pop(context);
                OppoFixLauncher.launchWhatsApp(whatsappNumber);
              },
            ),
            ListTile(
              leading: Icon(Icons.call, color: Colors.green),
              title: Text('Voice Call'),
              onTap: () {
                Navigator.pop(context);
                OppoFixLauncher.launchWhatsApp('$whatsappNumber?call');
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: Colors.green),
              title: Text('Video Call'),
              onTap: () {
                Navigator.pop(context);
                OppoFixLauncher.launchWhatsApp('$whatsappNumber?video');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionalCard({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text(value),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = authController.userRole.value == 'admin';
    final isOwner = contact.ownerId == authController.firebaseUser.value?.uid;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareContact),
          if (isAdmin || isOwner)
            IconButton(
                icon: Icon(Icons.delete), onPressed: _confirmDeleteContact),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://i.pinimg.com/736x/e8/d7/d0/e8d7d05f392d9c2cf0285ce928fb9f4a.jpg',
              ),
            ),
            SizedBox(height: 16),
            Text(contact.name,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),

            /// Primary Phone
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Bootstrap.phone_fill, color: Colors.green),
                title: Text('Mobile'),
                subtitle: Text(contact.phone),
                trailing: IconButton(
                  icon: Icon(Icons.message, color: Colors.blue),
                  onPressed: () => OppoFixLauncher.launchSMS(contact.phone),
                ),
                onTap: () => OppoFixLauncher.launchPhone(contact.phone),
              ),
            ),

            /// Additional Phones
            // if (contact.phoneNumbers != null)
            //   ...contact.phoneNumbers!.map((number) => Card(
            //         elevation: 4,
            //         margin: EdgeInsets.symmetric(vertical: 4),
            //         child: ListTile(
            //           leading: Icon(Bootstrap.phone, color: Colors.green),
            //           title: Text(number),
            //           subtitle: Text('Mobile'),
            //           trailing: IconButton(
            //             icon: Icon(Icons.message, color: Colors.blue),
            //             onPressed: () => OppoFixLauncher.launchSMS(number),
            //           ),
            //           onTap: () => OppoFixLauncher.launchPhone(number),
            //         ),
            //       )),
            /// Additional Phones
if (contact.phoneNumbers.isNotEmpty)
  ...contact.phoneNumbers
      .skip(contact.importedFromCsv ? 1 : 0) // 👈 only skip if CSV
      .map((number) => Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(Bootstrap.phone, color: Colors.green),
          title: Text(number),
          subtitle: Text('Mobile'),
          trailing: IconButton(
            icon: Icon(Icons.message, color: Colors.blue),
            onPressed: () => OppoFixLauncher.launchSMS(number),
          ),
          onTap: () => OppoFixLauncher.launchPhone(number),
        ),
      )),


            /// Landlines
            _buildOptionalCard(
              icon: Bootstrap.telephone_fill,
              label: 'Land Line',
              value: contact.landline,
              onTap: () => OppoFixLauncher.launchPhone(contact.landline!),
              color: Colors.green,
            ),

            // if (contact.landlineNumbers != null)
            //   ...contact.landlineNumbers!.map((line) => Card(
            //         elevation: 4,
            //         margin: EdgeInsets.symmetric(vertical: 4),
            //         child: ListTile(
            //           leading:
            //               Icon(Bootstrap.telephone_fill, color: Colors.green),
            //           title: Text(line),
            //           subtitle: Text('Land Line'),
            //           onTap: () => OppoFixLauncher.launchPhone(line),
            //         ),
            //       )),

            if (contact.landlineNumbers.isNotEmpty)
  ...contact.landlineNumbers
      .skip(contact.importedFromCsv ? 1 : 0) // 👈 skip only if CSV
      .map((landline) => Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(Bootstrap.telephone, color: Colors.orange),
              title: Text(landline),
              subtitle: Text('Landline'),
              onTap: () => OppoFixLauncher.launchPhone(landline),
            ),
          )),
            /// Email (Admins only)
  //           if (isAdmin) ...[
  //             _buildOptionalCard(
  //               icon: Icons.email,
  //               label: 'Email',
  //               value: contact.email,
  //               onTap: () => OppoFixLauncher.launchEmail(contact.email),
  //               color: Colors.red,
  //             ),
  //             if (contact.emailAddresses.isNotEmpty)
  // ...contact.emailAddresses
  //     .skip(contact.importedFromCsv ? 1 : 0) // 👈 skip only if CSV
  //     .map((email) => Card(
  //           elevation: 4,
  //           margin: EdgeInsets.symmetric(vertical: 4),
  //           child: ListTile(
  //             leading: Icon(Icons.email, color: Colors.red),
  //             title: Text(email),
  //             subtitle: Text('Email'),
  //             onTap: () => OppoFixLauncher.launchEmail(email),
  //           ),
  //         )),
  //           ],
            /// Email
            _buildOptionalCard(
              icon: Icons.email,
              label: 'Email',
              value: contact.email,
              onTap: () => OppoFixLauncher.launchEmail(contact.email),
              color: Colors.red,
            ),

            if (contact.emailAddresses != null)
              ...contact.emailAddresses!.map((email) => Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.email, color: Colors.red),
                      title: Text(email),
                      onTap: () => OppoFixLauncher.launchEmail(email),
                    ),
                  )),

            /// WhatsApp
            if (contact.whatsapp != null && contact.whatsapp!.isNotEmpty)
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Bootstrap.whatsapp, color: Colors.green),
                  title: Text('WhatsApp: ${contact.whatsapp}'),
                  subtitle: Text('Chat with ${contact.name}'),
                  onTap: () => _showWhatsAppOptions(contact.whatsapp!),
                ),
              ),

            /// Facebook
            _buildOptionalCard(
              icon: Bootstrap.facebook,
              label: 'Facebook',
              value: contact.facebook,
              onTap: () => OppoFixLauncher.launchFacebook(contact.facebook!),
              color: Colors.blue,
            ),

            /// Instagram
            _buildOptionalCard(
              icon: Bootstrap.instagram,
              label: 'Instagram',
              value: contact.instagram,
              onTap: () => OppoFixLauncher.launchInstagram(contact.instagram),
              color: Colors.pink,
            ),

            /// YouTube
            _buildOptionalCard(
              icon: Bootstrap.youtube,
              label: 'YouTube',
              value: contact.youtube,
              onTap: () => OppoFixLauncher.launchYouTube(
                  'https://www.youtube.com/${contact.youtube}'),
              color: Colors.red,
            ),

            /// Website
            _buildOptionalCard(
              icon: Icons.language,
              label: 'Website',
              value: contact.website,
              onTap: () {
                if (contact.website != null && contact.website!.isNotEmpty) {
                  final url = contact.website!.startsWith('http')
                      ? contact.website!
                      : 'https://${contact.website!}';
                  OppoFixLauncher.launchCustomURL(Uri.parse(url));
                }
              },
              color: Colors.blueAccent,
            ),

            /// Custom Fields
            if (contact.customFields != null &&
                contact.customFields!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Custom Fields",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final entries = contact.customFields!.entries.toList();
                        final movedItem = entries.removeAt(oldIndex);
                        entries.insert(newIndex, movedItem);
                        setState(() {
                          contact.customFields = Map.fromEntries(entries);
                        });
                        await _saveCustomFieldsToFirebase();
                      },
                      children: contact.customFields!.entries.map((entry) {
                        return Card(
                          key: ValueKey(entry.key),
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text(entry.value ?? 'No value'),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: (isAdmin || isOwner)
          ? FloatingActionButton(
              onPressed: () async {
                final updatedContact = await Navigator.push<Contact>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditContactPage(contact: contact),
                  ),
                );

                if (updatedContact != null) {
                  setState(() => contact = updatedContact);
                }
              },
              child: Icon(Icons.edit),
            )
          : null,
    );
  }
}
