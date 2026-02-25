


import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'package:file_picker/file_picker.dart';
import 'package:vcard_vcf/vcard.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import '../model/contact.dart';

class ContactImportController extends GetxController {
  /// Device contacts from phone
  var deviceContacts = <Contact>[].obs;

  /// Imported contacts from VCF/CSV
  var importedContacts = <Contact>[].obs;

  /// Hive box for all contacts
  late Box<Contact> contactsBox;

  @override
  void onInit() {
    super.onInit();
    initHive();
  }

  /// Initialize Hive box and load imported contacts only
  Future<void> initHive() async {
    contactsBox = await Hive.openBox<Contact>('contacts');
    loadImportedContacts();
  }

  /// Load only contacts that were imported (not device contacts)
  void loadImportedContacts() {
    importedContacts.value =
        contactsBox.values.where((c) => c.importedFromCsv).toList();
  }

  /// Fetch device contacts (phone contacts)
  Future<void> fetchDeviceContacts() async {
    final permissionGranted = await FlutterContacts.requestPermission();
    if (!permissionGranted) {
      Get.snackbar('Permission Denied', 'Contacts access is required.');
      return;
    }

    final rawContacts = await FlutterContacts.getContacts(withProperties: true);

    deviceContacts.value = rawContacts.map((c) {
      final phoneNumbers = c.phones.map((p) => p.number).toList();
      final emails = c.emails.map((e) => e.address).toList();

      return Contact(
        id: '',
        name: c.displayName,
        phone: phoneNumbers.isNotEmpty ? phoneNumbers.first : '',
        landline: null,
        email: emails.isNotEmpty ? emails.first : '',
        ownerId: '',
        isFavorite: false,
        phoneNumbers: phoneNumbers,
        landlineNumbers: [],
        emailAddresses: emails,
        customFields: {},
        whatsapp: null,
        facebook: null,
        instagram: null,
        youtube: null,
        isSynced: false,
        importedFromCsv: false, // device contact
      );
    }).toList();
  }

  /// Import contacts from a VCF file
  Future<void> importContactsFromVcfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf'],
    );

    if (result == null || result.files.single.path == null) {
      Get.snackbar('Import Cancelled', 'No VCF file selected.');
      return;
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString();

    final lines = content.split(RegExp(r'\r?\n'));
    final contacts = <Contact>[];
    VCard? currentVCard;

    for (var line in lines) {
      line = line.trim();
      if (line == 'BEGIN:VCARD') {
        currentVCard = VCard();
      } else if (line == 'END:VCARD') {
        if (currentVCard != null) {
          final phoneNumbers = <String>[];
          final emails = <String>[];

          if (currentVCard.workPhone != null) phoneNumbers.add(currentVCard.workPhone!);
          if (currentVCard.homePhone != null) phoneNumbers.add(currentVCard.homePhone!);
          if (currentVCard.cellPhone != null) phoneNumbers.add(currentVCard.cellPhone!);
          if (currentVCard.email != null) emails.add(currentVCard.email!);

          contacts.add(Contact(
            id: '',
            name: currentVCard.firstName,
            phone: phoneNumbers.isNotEmpty ? phoneNumbers.first : '',
            landline: null,
            email: emails.isNotEmpty ? emails.first : '',
            ownerId: '',
            isFavorite: false,
            phoneNumbers: phoneNumbers,
            landlineNumbers: [],
            emailAddresses: emails,
            customFields: {},
            whatsapp: null,
            facebook: null,
            instagram: null,
            youtube: null,
            isSynced: false,
            importedFromCsv: true,
          ));
        }
        currentVCard = null;
      } else if (currentVCard != null) {
        final separatorIndex = line.indexOf(':');
        if (separatorIndex != -1) {
          final key = line.substring(0, separatorIndex).toUpperCase();
          final value = line.substring(separatorIndex + 1);
          switch (key) {
            case 'FN':
              currentVCard.firstName = value;
              break;
            case 'TEL;WORK':
              currentVCard.workPhone = value;
              break;
            case 'TEL;HOME':
              currentVCard.homePhone = value;
              break;
            case 'TEL;CELL':
              currentVCard.cellPhone = value;
              break;
            case 'EMAIL':
              currentVCard.email = value;
              break;
          }
        }
      }
    }

    // Save imported contacts to Hive
    for (var contact in contacts) {
      await contactsBox.add(contact);
    }

    // Update only importedContacts list
    importedContacts.value = contacts;

    Get.snackbar('Import Successful', '${contacts.length} contacts imported from VCF.');
  }

  /// Import contacts from CSV
  Future<void> importContactsFromCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      Get.snackbar('Import Cancelled', 'No CSV file selected.');
      return;
    }

    final file = File(result.files.single.path!);
    var content = await file.readAsString();

    // Remove BOM if present
    if (content.isNotEmpty && content.codeUnitAt(0) == 0xFEFF) content = content.substring(1);

    List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(content);
    if (rows.isNotEmpty && rows.first.length == 1) rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ';').convert(content);
    if (rows.isNotEmpty && rows.first.length == 1) rows = const CsvToListConverter(eol: '\n', fieldDelimiter: '\t').convert(content);

    if (rows.isEmpty) {
      Get.snackbar('Import Failed', 'CSV file is empty.');
      return;
    }

    final imported = <Contact>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final name = row.length > 0 ? row[0].toString().trim() : '';
      final phone = row.length > 1 ? row[1].toString().trim() : '';
      final landline = row.length > 2 ? row[2].toString().trim() : '';
      final email = row.length > 3 ? row[3].toString().trim() : '';
      final website = row.length > 4 ? row[4].toString().trim() : '';

      if (name.isEmpty && phone.isEmpty && landline.isEmpty && email.isEmpty && website.isEmpty) continue;

      final phoneList = phone.isNotEmpty ? phone.split(';').map((e) => e.trim()).toList() : <String>[];
      final landlineList = landline.isNotEmpty ? landline.split(';').map((e) => e.trim()).toList() : <String>[];
      final emailList = email.isNotEmpty ? email.split(';').map((e) => e.trim()).toList() : <String>[];

      final newContact = Contact(
        id: '',
        name: name,
        phone: phoneList.isNotEmpty ? phoneList.first : '',
        landline: landlineList.isNotEmpty ? landlineList.first : null,
        email: emailList.isNotEmpty ? emailList.first : '',
        ownerId: '',
        isFavorite: false,
        phoneNumbers: phoneList,
        landlineNumbers: landlineList,
        emailAddresses: emailList,
        customFields: {},
        whatsapp: null,
        facebook: null,
        instagram: null,
        youtube: null,
        website: website.isNotEmpty ? website : null,
        isSynced: false,
        importedFromCsv: true,
      );

      await contactsBox.add(newContact);
      imported.add(newContact);
    }

    importedContacts.value = imported;

    Get.snackbar('Import Successful', '${imported.length} contacts imported from CSV.');
  }
}
