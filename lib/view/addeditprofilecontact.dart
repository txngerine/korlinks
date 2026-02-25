// ignore_for_file: use_super_parameters, unnecessary_import, prefer_const_constructors, no_leading_underscores_for_local_identifiers, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../model/contact.dart';
import '../controllers/addeditprofilecontact_controller.dart';
import 'package:get/get.dart';

class AddEditProfileContactPage extends StatelessWidget {
  final Contact? contact;

  const AddEditProfileContactPage({Key? key, this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AddEditProfileContactController controller =
        Get.put(AddEditProfileContactController(contact));

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
              onPressed: () async {
                await controller.saveContact(context);
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
                  controller: controller.nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  icon: Bootstrap.person,
                  focusNode: controller.nameFocusNode,
                  nextFocusNode: controller.phoneFocusNode,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  icon: Bootstrap.phone,
                  keyboardType: TextInputType.phone,
                  focusNode: controller.phoneFocusNode,
                  nextFocusNode: controller.landFocusNode,
                ),
                Obx(() {
                  return Column(
                    children: controller.phoneNumbersControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController phoneController = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: phoneController,
                              labelText: 'Additional Phone',
                              hintText: 'Enter additional phone',
                              icon: Bootstrap.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => controller.removePhoneNumber(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: controller.addPhoneNumber,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add Phone Number',style: TextStyle(color: Colors.black),),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.landlineController,
                  labelText: 'LandLine Number',
                  hintText: 'Enter LandLine number',
                  icon: Bootstrap.phone,
                  keyboardType: TextInputType.phone,
                  focusNode: controller.landFocusNode,
                  nextFocusNode: controller.emailFocusNode,
                ),
                Obx(() {
                  return Column(
                    children: controller.landlineNumbersControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController landlineController = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: landlineController,
                              labelText: 'Additional Landline',
                              hintText: 'Enter additional Landline',
                              keyboardType: TextInputType.phone,
                              icon: Bootstrap.phone,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => controller.removeLandlineNumbers(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: controller.addLandlineNumbers,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add Landline Number',style: TextStyle(color: Colors.black),),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                  icon: Icons.email,
                  focusNode: controller.emailFocusNode,
                  nextFocusNode: controller.whatsappFocusNode,
                ),
                Obx(() {
                  return Column(
                    children: controller.emailAddressesControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController emailController = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildCurvedTextField(
                              context: context,
                              controller: emailController,
                              labelText: 'Additional Email',
                              hintText: 'Enter additional email',
                              icon: Icons.email,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => controller.removeEmailAddress(index),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: controller.addEmailAddress,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add Email Address',style: TextStyle(color: Colors.black),),
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.whatsappController,
                  labelText: 'WhatsApp',
                  hintText: 'Enter WhatsApp number',
                  icon: Bootstrap.whatsapp,
                  focusNode: controller.whatsappFocusNode,
                  nextFocusNode: controller.facebookFocusNode,
                  iconColor: Color(0xFF25D366),
                ),SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.facebookController,
                  labelText: 'Facebook',
                  hintText: 'Enter Facebook URL',
                  icon: Bootstrap.facebook,
                  focusNode: controller.facebookFocusNode,
                  iconColor: Color(0xFF1877F2),
                  nextFocusNode: controller.instagramFocusNode,
                ),SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.instagramController,
                  labelText: 'Instagram',
                  hintText: 'Enter Instagram URL',
                  icon: Bootstrap.instagram,
                  focusNode: controller.instagramFocusNode,
                  iconColor: Color(0xFFC13584),
                  nextFocusNode: controller.youtubeFocusNode,
                ),SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.youtubeController,
                  labelText: 'YouTube',
                  hintText: 'Enter YouTube URL',
                  icon: Bootstrap.youtube,
                  focusNode: controller.youtubeFocusNode,
                  iconColor: Color(0xFFFF0000),
                  nextFocusNode: null,
                ),
                SizedBox(height: 16),
                _buildCurvedTextField(
                  context: context,
                  controller: controller.websiteController,
                  labelText: 'Website',
                  hintText: 'Enter website URL',
                  icon: Icons.language,
                  focusNode: controller.websiteFocusNode,
                  nextFocusNode: null,
                ),
                SizedBox(height: 24),
                Obx(() {
                  return Center(
                    child: Column(
                      children: controller.customFields.asMap().entries.map((entry) {
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
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => controller.removeCustomField(index),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }),
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: controller.addCustomField,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add Custom Field',style: TextStyle(color: Colors.black),),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                    onPressed: () async => await controller.saveContact(context),
                  child: Text(contact == null ? 'Save Contact' : 'Update Contact',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Save and publish; saveContact now returns the saved Contact
                        final saved = await controller.saveContact(context);
                        if (saved != null) {
                          await controller.publishContactToFirebase(saved);
                        }
                      },
      icon: Icon(Icons.cloud_upload, color: Colors.white),
      label: Text('Publish', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      prefixIcon: icon != null ? Icon(icon, color: iconColor ?? Colors.blue) : null,
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