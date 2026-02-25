// ignore_for_file: use_super_parameters, unnecessary_import, prefer_const_constructors, no_leading_underscores_for_local_identifiers, sort_child_properties_last

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../model/contact.dart';
import '../controllers/contact_controller.dart';
import 'package:get/get.dart';

class AddEditContactPage extends StatelessWidget {
  final Contact? contact;

  const AddEditContactPage({Key? key, this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ContactController contactController = Get.find<ContactController>();

    // Controllers for Text Fields
    TextEditingController nameController =
        TextEditingController(text: contact?.name ?? '');
    TextEditingController phoneController =
        TextEditingController(text: contact?.phone ?? '');
    TextEditingController landlineController =
        TextEditingController(text: contact?.landline ?? '');
    TextEditingController emailController =
        TextEditingController(text: contact?.email ?? '');
    TextEditingController whatsappController =
        TextEditingController(text: contact?.whatsapp ?? '');
    TextEditingController facebookController =
        TextEditingController(text: contact?.facebook ?? '');
    TextEditingController instagramController =
        TextEditingController(text: contact?.instagram ?? '');
    TextEditingController youtubeController =
        TextEditingController(text: contact?.youtube ?? '');
    TextEditingController websiteController =
        TextEditingController(text: contact?.website ?? ''); // Add this line

    // FocusNodes for each TextField
    FocusNode nameFocusNode = FocusNode();
    FocusNode phoneFocusNode = FocusNode();
    FocusNode landFocusNode = FocusNode();
    FocusNode emailFocusNode = FocusNode();
    FocusNode whatsappFocusNode = FocusNode();
    FocusNode facebookFocusNode = FocusNode();
    FocusNode instagramFocusNode = FocusNode();
    FocusNode youtubeFocusNode = FocusNode();
    FocusNode websiteFocusNode = FocusNode(); // Add this line

    // Reactive custom fields list
    RxList<Map<String, dynamic>> customFields = <Map<String, dynamic>>[].obs;

    // Reactive phone numbers, emails, and landlines lists
    RxList<TextEditingController> phoneNumbersControllers =
        <TextEditingController>[].obs;
    RxList<TextEditingController> emailAddressesControllers =
        <TextEditingController>[].obs;
    RxList<TextEditingController> landlineNumbersControllers =
        <TextEditingController>[].obs;

    // Load custom fields, phone numbers, and emails if contact exists
    if (contact != null) {
      // Load custom fields
      contact!.customFields?.forEach((label, value) {
        customFields.add({
          'label': label,
          'labelController': TextEditingController(text: label),
          'valueController': TextEditingController(text: value),
        });
      });

      // Load phone numbers
      contact!.phoneNumbers?.forEach((phone) {
        phoneNumbersControllers.add(TextEditingController(text: phone));
      });

      // Load additional emails
      contact!.emailAddresses?.forEach((email) {
        emailAddressesControllers.add(TextEditingController(text: email));
      });

      // Load additional landline numbers
      contact!.landlineNumbers?.forEach((landline) {
        landlineNumbersControllers.add(TextEditingController(text: landline));
      });
    }

    // Validation function
    bool _validateFields(BuildContext context) {
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name is a required field.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      if (!RegExp(r'^[a-zA-Z0-9\s\u0D00-\u0D7F]+$')
          .hasMatch(nameController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please enter a valid name in English, Malayalam, or with numbers.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      return true;
    }

    void _saveContact(BuildContext context) {
      if (!_validateFields(context)) return;
      final user = FirebaseAuth.instance.currentUser;

      // Collect custom fields
      Map<String, String> customFieldsMap = Map.fromEntries(
        customFields.map((field) => MapEntry(
              field['labelController']!.text,
              field['valueController']!.text,
            )),
      );

      // Collect phone numbers
      List<String> phoneNumbers = phoneNumbersControllers
          .map((controller) => controller.text)
          .where((number) => number.isNotEmpty)
          .toList();

      // Collect additional emails
      List<String> emailAddresses = emailAddressesControllers
          .map((controller) => controller.text)
          .where((email) => email.isNotEmpty)
          .toList();

      // Collect landline numbers
      List<String> landlineNumbers = landlineNumbersControllers
          .map((controller) => controller.text)
          .where((landline) => landline.isNotEmpty)
          .toList();

      bool isAdmin = contactController.isAdmin();

      if (contact == null) {
        Contact newContact = Contact(
          id: '',
          name: nameController.text,
          phone: phoneController.text,
          landline: landlineController.text,
          email: emailController.text,
          ownerId: user!.uid,
          customFields: customFieldsMap,
          phoneNumbers: phoneNumbers,
          emailAddresses: emailAddresses,
          landlineNumbers: landlineNumbers,
          whatsapp: whatsappController.text,
          facebook: facebookController.text,
          instagram: instagramController.text,
          youtube: youtubeController.text,
          website: websiteController.text,
          isFavorite: false,
        );

        if (isAdmin) {
          // contactController.addContactToFirebaseIfAdmin(newContact);
          contactController.addContact(newContact);
        } else {
          contactController.addContact(newContact);
        }

        Navigator.pop(context, newContact);
      } else {
        // Update existing contact object
        contact!
          ..name = nameController.text
          ..phone = phoneController.text
          ..landline = landlineController.text
          ..email = emailController.text
          ..customFields = customFieldsMap
          ..phoneNumbers = phoneNumbers
          ..emailAddresses = emailAddresses
          ..landlineNumbers = landlineNumbers
          ..whatsapp = whatsappController.text
          ..facebook = facebookController.text
          ..instagram = instagramController.text
          ..youtube = youtubeController.text
          ..website = websiteController.text;

        contactController.editContact(
          contact: contact!,
          name: contact!.name,
          phone: contact!.phone,
          landline: contact!.landline,
          email: contact!.email ?? '',
          phoneNumbers: contact!.phoneNumbers,
          landlineNumbers: contact!.landlineNumbers,
          emailAddresses: contact!.emailAddresses,
          customFields: contact!.customFields,
          whatsapp: contact!.whatsapp,
          facebook: contact!.facebook,
          instagram: contact!.instagram,
          youtube: contact!.youtube,
        );

        if (isAdmin) {
          // contactController.updateContactToFirebaseIfAdmin(contact!);
          contactController.updateContact(contact!);
        } else {
          contactController.updateContact(contact!);
        }

        Navigator.pop(context, contact);
      }
    }

    // Add phone number
    void _addPhoneNumber() {
      phoneNumbersControllers.add(TextEditingController());
    }

    // Remove phone number
    void _removePhoneNumber(int index) {
      phoneNumbersControllers.removeAt(index);
    }

    // Add email address
    void _addEmailAddress() {
      emailAddressesControllers.add(TextEditingController());
    }

    // Remove email address
    void _removeEmailAddress(int index) {
      emailAddressesControllers.removeAt(index);
    }

    // Add landline number
    void _addLandlineNumbers() {
      landlineNumbersControllers.add(TextEditingController());
    }

    // Remove landline number
    void _removeLandlineNumbers(int index) {
      landlineNumbersControllers.removeAt(index);
    }

    // Add custom field
    void _addCustomField() {
      customFields.add({
        'label': '',
        'labelController': TextEditingController(),
        'valueController': TextEditingController(),
      });
    }

    // Remove custom field
    void _removeCustomField(int index) {
      customFields.removeAt(index);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(contact == null ? 'New Contact' : 'Edit Contact'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (contact == null)
            IconButton(
              icon: Icon(Icons.sync),
              tooltip: 'Sync to Firebase (Admin only)',
              onPressed: () {
                // Collect custom fields
                Map<String, String> customFieldsMap = Map.fromEntries(
                  customFields.map((field) => MapEntry(
                        field['labelController']!.text,
                        field['valueController']!.text,
                      )),
                );

                // Collect phone numbers
                List<String> phoneNumbers = phoneNumbersControllers
                    .map((controller) => controller.text)
                    .where((number) => number.isNotEmpty)
                    .toList();

                // Collect additional emails
                List<String> emailAddresses = emailAddressesControllers
                    .map((controller) => controller.text)
                    .where((email) => email.isNotEmpty)
                    .toList();

                // Collect landline numbers
                List<String> landlineNumbers = landlineNumbersControllers
                    .map((controller) => controller.text)
                    .where((landline) => landline.isNotEmpty)
                    .toList();

                Contact newContact = Contact(
                  id: '',
                  name: nameController.text,
                  phone: phoneController.text,
                  landline: landlineController.text,
                  email: emailController.text,
                  ownerId: 'admin',
                  customFields: customFieldsMap,
                  phoneNumbers: phoneNumbers,
                  emailAddresses: emailAddresses,
                  landlineNumbers: landlineNumbers,
                  whatsapp: whatsappController.text,
                  facebook: facebookController.text,
                  instagram: instagramController.text,
                  youtube: youtubeController.text,
                  isFavorite: false,
                );
                contactController.addContactToFirebaseIfAdmin(newContact);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurvedTextField(
                  context: context,
                  controller: nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  icon: Bootstrap.person,
                  focusNode: nameFocusNode,
                  nextFocusNode: phoneFocusNode,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  icon: Bootstrap.phone,
                  keyboardType: TextInputType.phone,
                  focusNode: phoneFocusNode,
                  nextFocusNode: landFocusNode,
                ),
                Obx(() {
                  return Column(
                    children:
                        phoneNumbersControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: controller,
                              labelText: 'Additional Phone',
                              hintText: 'Enter additional phone',
                              icon: Bootstrap.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePhoneNumber(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _addPhoneNumber,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text(
                    'Add Phone Number',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: landlineController,
                  labelText: 'LandLine Number',
                  hintText: 'Enter LandLine number',
                  icon: Bootstrap.phone,
                  keyboardType: TextInputType.phone,
                  focusNode: landFocusNode,
                  nextFocusNode: emailFocusNode,
                ),
                Obx(() {
                  return Column(
                    children:
                        landlineNumbersControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: controller,
                              labelText: 'Additional Landline',
                              hintText: 'Enter additional Landline',
                              keyboardType: TextInputType.phone,
                              icon: Bootstrap.phone,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeLandlineNumbers(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _addLandlineNumbers,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text(
                    'Add Landline Number',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                  icon: Icons.email,
                  focusNode: emailFocusNode,
                  nextFocusNode: whatsappFocusNode,
                ),
                Obx(() {
                  return Column(
                    children:
                        emailAddressesControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: controller,
                              labelText: 'Additional Email',
                              hintText: 'Enter additional email',
                              icon: Icons.email,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeEmailAddress(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _addEmailAddress,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text(
                    'Add Email Address',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: whatsappController,
                  labelText: 'WhatsApp',
                  hintText: 'Enter WhatsApp number',
                  icon: Bootstrap.whatsapp,
                  focusNode: whatsappFocusNode,
                  nextFocusNode: facebookFocusNode,
                  iconColor: Color(0xFF25D366),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: facebookController,
                  labelText: 'Facebook',
                  hintText: 'Enter Facebook URL',
                  icon: Bootstrap.facebook,
                  focusNode: facebookFocusNode,
                  iconColor: Color(0xFF1877F2),
                  nextFocusNode: instagramFocusNode,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: instagramController,
                  labelText: 'Instagram',
                  hintText: 'Enter Instagram URL',
                  icon: Bootstrap.instagram,
                  focusNode: instagramFocusNode,
                  iconColor: Color(0xFFC13584),
                  nextFocusNode: youtubeFocusNode,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: youtubeController,
                  labelText: 'YouTube',
                  hintText: 'Enter YouTube URL',
                  icon: Bootstrap.youtube,
                  focusNode: youtubeFocusNode,
                  iconColor: Color(0xFFFF0000),
                  nextFocusNode: null,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: websiteController,
                  labelText: 'Website',
                  hintText: 'Enter website URL',
                  icon: Icons.language,
                  focusNode: websiteFocusNode,
                  nextFocusNode: null,
                ),
                SizedBox(height: 24),
                Obx(() {
                  return Center(
                    child: Column(
                      children: customFields.asMap().entries.map((entry) {
                        int index = entry.key;
                        var field = entry.value;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildCurvedTextField(
                                  context: context,
                                  controller: field['labelController'],
                                  labelText: 'Field Label',
                                  hintText: 'Custom Field Label',
                                  focusNode: null,
                                ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildCurvedTextField(
                                  context: context,
                                  controller: field['valueController'],
                                  labelText: 'Field Value',
                                  hintText: 'Custom Field Value',
                                  focusNode: null,
                                ),
                            ),
                            IconButton(
                              icon:
                                  Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeCustomField(index),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _addCustomField,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text(
                    'Add Custom Field',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (contactController.isAdmin())
                      ElevatedButton(
                        onPressed: () {
                          contactController
                              .updateContactToFirebaseIfAdmin(contact!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Contact published successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Publish Contact',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child:
                          Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      onPressed: () => _saveContact(context),
                      child: Text(
                        contact == null ? 'Save Contact' : 'Update Contact',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    IconData? icon,
    Color? iconColor, // Add this parameter
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        prefixIcon:
            icon != null ? Icon(icon, color: iconColor ?? Colors.blue) : null,
        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
