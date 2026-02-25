import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/contact.dart';
import '../controllers/contact_controller.dart';

class AddEditProfileContactController extends GetxController {
  final Contact? contact;
  final ContactController contactController = Get.find<ContactController>();

  // Text controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController landlineController;
  late TextEditingController emailController;
  late TextEditingController whatsappController;
  late TextEditingController facebookController;
  late TextEditingController instagramController;
  late TextEditingController youtubeController;
  late TextEditingController websiteController;

  // Focus nodes
  late FocusNode nameFocusNode;
  late FocusNode phoneFocusNode;
  late FocusNode landFocusNode;
  late FocusNode emailFocusNode;
  late FocusNode whatsappFocusNode;
  late FocusNode facebookFocusNode;
  late FocusNode instagramFocusNode;
  late FocusNode youtubeFocusNode;
  late FocusNode websiteFocusNode;

  // Reactive lists
  RxList<Map<String, dynamic>> customFields = <Map<String, dynamic>>[].obs;
  RxList<TextEditingController> phoneNumbersControllers = <TextEditingController>[].obs;
  RxList<TextEditingController> emailAddressesControllers = <TextEditingController>[].obs;
  RxList<TextEditingController> landlineNumbersControllers = <TextEditingController>[].obs;

  AddEditProfileContactController(this.contact);

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: contact?.name ?? '');
    phoneController = TextEditingController(text: contact?.phone ?? '');
    landlineController = TextEditingController(text: contact?.landline ?? '');
    emailController = TextEditingController(text: contact?.email ?? '');
    whatsappController = TextEditingController(text: contact?.whatsapp ?? '');
    facebookController = TextEditingController(text: contact?.facebook ?? '');
    instagramController = TextEditingController(text: contact?.instagram ?? '');
    youtubeController = TextEditingController(text: contact?.youtube ?? '');
    websiteController = TextEditingController(text: contact?.website ?? '');

    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();
    landFocusNode = FocusNode();
    emailFocusNode = FocusNode();
    whatsappFocusNode = FocusNode();
    facebookFocusNode = FocusNode();
    instagramFocusNode = FocusNode();
    youtubeFocusNode = FocusNode();
    websiteFocusNode = FocusNode();

    if (contact != null) {
      contact!.customFields.forEach((label, value) {
        customFields.add({
          'label': label,
          'labelController': TextEditingController(text: label),
          'valueController': TextEditingController(text: value),
        });
      });
      contact!.phoneNumbers.forEach((phone) {
        phoneNumbersControllers.add(TextEditingController(text: phone));
      });
      contact!.emailAddresses.forEach((email) {
        emailAddressesControllers.add(TextEditingController(text: email));
      });
      contact!.landlineNumbers.forEach((landline) {
        landlineNumbersControllers.add(TextEditingController(text: landline));
      });
    }
  }

  bool validateFields(BuildContext context) {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name is a required field.'), backgroundColor: Colors.red),
      );
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\u0D00-\u0D7F]+$').hasMatch(nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid name in English, Malayalam, or with numbers.'), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  Future<Contact?> saveContact(BuildContext context) async {
    if (!validateFields(context)) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to save a contact.'), backgroundColor: Colors.red),
      );
      return null;
    }

    // Check if the name already exists and was uploaded by an admin
    try {
      final query = await FirebaseFirestore.instance
          .collection('contacts')
          .where('name', isEqualTo: nameController.text.trim())
          .get();
      for (var doc in query.docs) {
        final data = doc.data();
        // Assuming admin contacts have a field 'isAdmin' true or ownerId is a known admin UID
        if (data['isAdmin'] == true || (data['ownerId'] != null && contactController.isAdminUid(data['ownerId']))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This name has already been uploaded by an admin. Please choose a different name.'), backgroundColor: Colors.red),
          );
          return null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking name: $e'), backgroundColor: Colors.red),
      );
      return null;
    }

    // Prevent duplicate contact on device (local Hive) by name
    try {
      final localContacts = contactController.contacts;
      final nameToCheck = nameController.text.trim();
      final isDuplicateLocal = localContacts.any((c) =>
        c.name.trim() == nameToCheck && (contact == null || c.id != contact!.id)
      );
      if (isDuplicateLocal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A contact with this name already exists on your device.'), backgroundColor: Colors.red),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking local contacts: $e'), backgroundColor: Colors.red),
      );
      return null;
    }

    // Build custom fields map but skip empty labels to avoid empty keys
    Map<String, String> customFieldsMap = Map.fromEntries(
      customFields.map((field) {
        final label = (field['labelController'] as TextEditingController).text.trim();
        final value = (field['valueController'] as TextEditingController).text;
        return MapEntry(label, value);
      }).where((entry) => entry.key.isNotEmpty),
    );

    List<String> phoneNumbers = phoneNumbersControllers
        .map((controller) => controller.text)
        .where((number) => number.isNotEmpty)
        .toList();
    List<String> emailAddresses = emailAddressesControllers
        .map((controller) => controller.text)
        .where((email) => email.isNotEmpty)
        .toList();
    List<String> landlineNumbers = landlineNumbersControllers
        .map((controller) => controller.text)
        .where((landline) => landline.isNotEmpty)
        .toList();

    bool isAdmin = contactController.isAdmin();

    if (contact == null) {
      // Use the authenticated user's UID as ownerId (not the name)
      final ownerId = user.uid;

      Contact newContact = Contact(
        id: '',
        name: nameController.text,
        phone: phoneController.text,
        landline: landlineController.text,
        email: emailController.text,
        ownerId: ownerId,
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
        await contactController.addContactToFirebaseIfAdmin(newContact);
      } else {
        await contactController.addContact(newContact);
      }
      Navigator.pop(context, newContact);
      return newContact;
    } else {
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

      await contactController.editContact(
        contact: contact!,
        name: contact!.name,
        phone: contact!.phone,
        landline: contact!.landline,
        email: contact!.email,
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
        await contactController.updateContactToFirebaseIfAdmin(contact!);
      } else {
        contactController.updateContact(contact!);
      }
      Navigator.pop(context, contact);
      return contact;
    }
  }

  // Add/remove methods
  void addPhoneNumber() => phoneNumbersControllers.add(TextEditingController());
  void removePhoneNumber(int index) {
    if (index < 0 || index >= phoneNumbersControllers.length) return;
    final ctrl = phoneNumbersControllers[index];
    phoneNumbersControllers.removeAt(index);
    try {
      ctrl.dispose();
    } catch (_) {}
  }

  void addEmailAddress() => emailAddressesControllers.add(TextEditingController());
  void removeEmailAddress(int index) {
    if (index < 0 || index >= emailAddressesControllers.length) return;
    final ctrl = emailAddressesControllers[index];
    emailAddressesControllers.removeAt(index);
    try {
      ctrl.dispose();
    } catch (_) {}
  }

  void addLandlineNumbers() => landlineNumbersControllers.add(TextEditingController());
  void removeLandlineNumbers(int index) {
    if (index < 0 || index >= landlineNumbersControllers.length) return;
    final ctrl = landlineNumbersControllers[index];
    landlineNumbersControllers.removeAt(index);
    try {
      ctrl.dispose();
    } catch (_) {}
  }

  void addCustomField() {
    customFields.add({
      'label': '',
      'labelController': TextEditingController(),
      'valueController': TextEditingController(),
    });
  }

  void removeCustomField(int index) {
    if (index < 0 || index >= customFields.length) return;
    final field = customFields[index];
    final labelCtrl = field['labelController'] as TextEditingController?;
    final valueCtrl = field['valueController'] as TextEditingController?;
    customFields.removeAt(index);
    try {
      labelCtrl?.dispose();
    } catch (_) {}
    try {
      valueCtrl?.dispose();
    } catch (_) {}
  }

  Future<void> publishContactToFirebase(Contact contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'You must be logged in to publish.');
      return;
    }
    contact.ownerId = user.uid;

    try {
      // Check for duplicate by name ONLY for this user
      final query = await FirebaseFirestore.instance
          .collection('contacts')
          .where('name', isEqualTo: contact.name)
          .where('ownerId', isEqualTo: user.uid)
          .get();

      if (query.docs.isNotEmpty) {
        // Block duplicate entirely
        Get.snackbar('Duplicate', 'A contact with this name already exists.');
        return;
      }

      // No duplicate, create new
      await FirebaseFirestore.instance
          .collection('contacts')
          .add({
        'name': contact.name,
        'phone': contact.phone,
        'landline': contact.landline,
        'email': contact.email,
        'ownerId': contact.ownerId,
        'customFields': contact.customFields,
        'phoneNumbers': contact.phoneNumbers,
        'emailAddresses': contact.emailAddresses,
        'landlineNumbers': contact.landlineNumbers,
        'whatsapp': contact.whatsapp,
        'facebook': contact.facebook,
        'instagram': contact.instagram,
        'youtube': contact.youtube,
        'website': contact.website,
        'isFavorite': contact.isFavorite,
      });
      Get.snackbar('Success', 'Contact published to Firebase.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish contact: $e');
    }
  }

  @override
  void onClose() {
    // Dispose single controllers
    try { nameController.dispose(); } catch (_) {}
    try { phoneController.dispose(); } catch (_) {}
    try { landlineController.dispose(); } catch (_) {}
    try { emailController.dispose(); } catch (_) {}
    try { whatsappController.dispose(); } catch (_) {}
    try { facebookController.dispose(); } catch (_) {}
    try { instagramController.dispose(); } catch (_) {}
    try { youtubeController.dispose(); } catch (_) {}
    try { websiteController.dispose(); } catch (_) {}

    // Dispose list controllers
    for (var c in phoneNumbersControllers) {
      try { c.dispose(); } catch (_) {}
    }
    for (var c in emailAddressesControllers) {
      try { c.dispose(); } catch (_) {}
    }
    for (var c in landlineNumbersControllers) {
      try { c.dispose(); } catch (_) {}
    }
    for (var field in customFields) {
      try { (field['labelController'] as TextEditingController?)?.dispose(); } catch (_) {}
      try { (field['valueController'] as TextEditingController?)?.dispose(); } catch (_) {}
    }

    // Dispose focus nodes
    try { nameFocusNode.dispose(); } catch (_) {}
    try { phoneFocusNode.dispose(); } catch (_) {}
    try { landFocusNode.dispose(); } catch (_) {}
    try { emailFocusNode.dispose(); } catch (_) {}
    try { whatsappFocusNode.dispose(); } catch (_) {}
    try { facebookFocusNode.dispose(); } catch (_) {}
    try { instagramFocusNode.dispose(); } catch (_) {}
    try { youtubeFocusNode.dispose(); } catch (_) {}
    try { websiteFocusNode.dispose(); } catch (_) {}

    super.onClose();
  }
}