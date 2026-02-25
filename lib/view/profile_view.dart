// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:korlinks/view/addeditprofilecontact.dart';
import '../controllers/auth_controller.dart';
import '../controllers/contact_controller.dart';
import '../model/contact.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final authController = Get.find<AuthController>();
  final contactController = Get.find<ContactController>();

  Map<String, dynamic> profileData = {};
  bool isLoading = true;

  final String hiveProfileBoxName = 'profileBox';
  final String hiveContactBoxName = 'contactBox';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    bool connected = await _isConnected();

    final userId = authController.firebaseUser.value?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in.');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (connected) {
      // Online: load from Firestore, then save to Hive
      try {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          profileData = userSnapshot.data() ?? {};

          await contactController.loadContactDetails(userId);

          // Save profileData to Hive
          var profileBox = await Hive.openBox(hiveProfileBoxName);
          await profileBox.put('profileData', profileData);

          // Save contactData to Hive
          var contactBox = await Hive.openBox(hiveContactBoxName);
          await contactBox.put('contactData', contactController.contactInfo);
        } else {
          Get.snackbar('Error', 'User profile not found.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to load profile data: $e');
      }
    } else {
      // Offline: load from Hive
      try {
        var profileBox = await Hive.openBox(hiveProfileBoxName);
        var contactBox = await Hive.openBox(hiveContactBoxName);

        profileData = Map<String, dynamic>.from(
            profileBox.get('profileData', defaultValue: {}));
        contactController.contactInfo = Map<String, dynamic>.from(
            contactBox.get('contactData', defaultValue: {}));
      } catch (e) {
        Get.snackbar('Error', 'Failed to load offline data: $e');
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _editProfile() async {
    final currentData = {
      'name': profileData['username'] ?? '',
      'email': profileData['email'] ?? '',
      'phone': contactController.contactInfo['phone'] ?? '',
      'phonenumbers': contactController.contactInfo['phonenumbers'] ?? [],
      'landline': contactController.contactInfo['landline'] ?? '',
      'landlinenumbers': contactController.contactInfo['landlinenumbers'] ?? [],
      'emailaddresses': contactController.contactInfo['emailaddresses'] ?? [],
      'facebook': contactController.contactInfo['facebook'] ?? '',
      'whatsapp': contactController.contactInfo['whatsapp'] ?? '',
      'instagram': contactController.contactInfo['instagram'] ?? '',
      'youtube': contactController.contactInfo['youtube'] ?? '',
      'website': contactController.contactInfo['website'] ?? '',
      'websites': contactController.contactInfo['websites'] ?? [],
      'address': contactController.contactInfo['address'] ?? '',
      'bio': profileData['bio'] ?? '',
    };

    // Convert map to Contact object
    final contact = mapToContact(currentData);

    // Await edited contact from the page
    final updatedContact = await Get.to<Contact?>(
      () => AddEditProfileContactPage(contact: contact),
    );

    if (updatedContact != null && mounted) {
      setState(() {
        profileData['username'] = updatedContact.name;
        profileData['email'] = updatedContact.email;
        // If you want to update bio, handle it in your AddEditProfileContactPage and Contact model

        contactController.contactInfo['phone'] = updatedContact.phone;
        contactController.contactInfo['phonenumbers'] =
            updatedContact.phoneNumbers;
        contactController.contactInfo['landline'] = updatedContact.landline;
        contactController.contactInfo['landlinenumbers'] =
            updatedContact.landlineNumbers;
        contactController.contactInfo['emailaddresses'] =
            updatedContact.emailAddresses;
        contactController.contactInfo['facebook'] = updatedContact.facebook;
        contactController.contactInfo['whatsapp'] = updatedContact.whatsapp;
        contactController.contactInfo['instagram'] = updatedContact.instagram;
        contactController.contactInfo['youtube'] = updatedContact.youtube;
        contactController.contactInfo['website'] = updatedContact.website;
        contactController.contactInfo['websites'] =
            []; // Add if you support multiple websites
        contactController.contactInfo['address'] =
            updatedContact.website; // Or address if you have it
      });

      // Update Hive storage as well to keep offline data updated
      var profileBox = await Hive.openBox(hiveProfileBoxName);
      await profileBox.put('profileData', profileData);

      var contactBox = await Hive.openBox(hiveContactBoxName);
      await contactBox.put('contactData', contactController.contactInfo);
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildMultipleInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        children: items
            .map((item) => ListTile(
                  title: Text(item),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactData = contactController.contactInfo;
    // final bool isAdmin = profileData['isAdmin'] == true;
    final bool isAdmin = profileData['role'] == 'admin';

    print('profileData: $profileData');
    print('isAdmin: $isAdmin');

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileData.isEmpty
              ? const Center(child: Text('No Profile Data Found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          profileData['profileImageUrl'] ??
                              'https://i.pinimg.com/736x/e8/d7/d0/e8d7d05f392d9c2cf0285ce928fb9f4a.jpg',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profileData['username'] ?? 'Name not available',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Similar _buildInfoCard and _buildMultipleInfoCard calls as before to show all info

                      if (profileData['email'] != null &&
                          profileData['email'].toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.email,
                          color: Colors.red,
                          title: profileData['email'],
                          subtitle: 'Email',
                        ),

                      if (contactData['emailaddresses'] != null &&
                          (contactData['emailaddresses'] as List).isNotEmpty)
                        _buildMultipleInfoCard(
                          icon: Icons.email_outlined,
                          color: Colors.red,
                          title: 'Email Addresses',
                          items:
                              List<String>.from(contactData['emailaddresses']),
                        ),

                      if (contactData['phone'] != null &&
                          contactData['phone']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.phone,
                          color: Colors.green,
                          title: contactData['phone'],
                          subtitle: 'Phone',
                        ),

                      if (contactData['phonenumbers'] != null &&
                          (contactData['phonenumbers'] as List).isNotEmpty)
                        _buildMultipleInfoCard(
                          icon: Icons.phone_android,
                          color: Colors.green,
                          title: 'Phone Numbers',
                          items: List<String>.from(contactData['phonenumbers']),
                        ),

                      if (contactData['landline'] != null &&
                          contactData['landline']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.phone,
                          color: Colors.blueGrey,
                          title: contactData['landline'],
                          subtitle: 'Landline',
                        ),

                      if (contactData['landlinenumbers'] != null &&
                          (contactData['landlinenumbers'] as List).isNotEmpty)
                        _buildMultipleInfoCard(
                          icon: Icons.phone_in_talk,
                          color: Colors.blueGrey,
                          title: 'Landline Numbers',
                          items:
                              List<String>.from(contactData['landlinenumbers']),
                        ),

                      if (contactData['website'] != null &&
                          contactData['website']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.web,
                          color: Colors.blue,
                          title: contactData['website'],
                          subtitle: 'Website',
                        ),

                      if (contactData['websites'] != null &&
                          (contactData['websites'] as List).isNotEmpty)
                        _buildMultipleInfoCard(
                          icon: Icons.web_outlined,
                          color: Colors.blue,
                          title: 'Websites',
                          items: List<String>.from(contactData['websites']),
                        ),

                      if (contactData['facebook'] != null &&
                          contactData['facebook']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.facebook,
                          color: Colors.blueAccent,
                          title: contactData['facebook'],
                          subtitle: 'Facebook',
                        ),

                      if (contactData['whatsapp'] != null &&
                          contactData['whatsapp']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.call,
                          color: Colors.green,
                          title: contactData['whatsapp'],
                          subtitle: 'WhatsApp',
                        ),

                      if (contactData['instagram'] != null &&
                          contactData['instagram']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.camera_alt,
                          color: Colors.pink,
                          title: contactData['instagram'],
                          subtitle: 'Instagram',
                        ),

                      if (contactData['youtube'] != null &&
                          contactData['youtube']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.video_library,
                          color: Colors.redAccent,
                          title: contactData['youtube'],
                          subtitle: 'YouTube',
                        ),

                      if (contactData['address'] != null &&
                          contactData['address']!.toString().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.location_on,
                          color: Colors.orange,
                          title: contactData['address'],
                          subtitle: 'Address',
                        ),

                      if (profileData['bio'] != null &&
                          profileData['bio']!.toString().isNotEmpty)
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              profileData['bio'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to FAQ page or show FAQ dialog
                Get.toNamed('/adminfaq'); // Or use your FAQ page route
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('FAQ'),
            )
          : null,
    );
  }

  // Add this helper inside _ProfileViewState (or as a top-level function)
  Contact mapToContact(Map<String, dynamic> data) {
    return Contact(
      id: '', // or data['id'] if you have it
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      landline: data['landline'] ?? '',
      email: data['email'] ?? '',
      ownerId: '', // or data['ownerId'] if you have it
      customFields: {}, // handle if you use custom fields
      phoneNumbers: List<String>.from(data['phonenumbers'] ?? []),
      emailAddresses: List<String>.from(data['emailaddresses'] ?? []),
      landlineNumbers: List<String>.from(data['landlinenumbers'] ?? []),
      whatsapp: data['whatsapp'] ?? '',
      facebook: data['facebook'] ?? '',
      instagram: data['instagram'] ?? '',
      youtube: data['youtube'] ?? '',
      website: data['website'] ?? '',
      isFavorite: false,
    );
  }
}
