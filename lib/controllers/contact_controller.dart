import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../model/contact.dart';
import 'auth_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ContactController extends GetxController {
  /// Returns true if the given ownerId is an admin.
  /// You can customize this logic as needed (e.g., check against a list of admin UIDs).
  bool isAdminUid(String ownerId) {
    // In your app, admin contacts use ownerId 'admin'.
    // If you use real UIDs for admins, add them to this list.
    return ownerId == 'admin';
  }
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController authController = Get.find<AuthController>();
  late Box<Contact> contactBox;

  RxList<Contact> contacts = <Contact>[].obs;
  RxList<Contact> filteredContacts = <Contact>[].obs;
  RxString searchQuery = ''.obs;
  RxMap<String, List<Contact>> groupedContacts = <String, List<Contact>>{}.obs;
  final RxMap<String, dynamic> contactData = <String, dynamic>{}.obs;

  Map<String, dynamic> _contactInfo = {};

  Map<String, dynamic> get contactInfo => _contactInfo;

  set contactInfo(Map<String, dynamic> value) {
    _contactInfo = value;
    update(); // Notify listeners (if you use GetX's update mechanism)
  }

  var isFetching = false.obs;
  var loadingMore = false.obs;

  DocumentSnapshot? lastVisible;
  final int pageSize = 25; // Start with smaller page size for faster initial load

  RxSet<Contact> selectedContacts = <Contact>{}.obs;
  RxBool isSelectionMode = false.obs;
RxList<Contact> deletedContacts = <Contact>[].obs;

  @override
  void onInit() {
    super.onInit();
    contactBox = Hive.box<Contact>('contacts');
    fetchContacts();
  }
  List<String> _getLocallyDeletedIds() {
    return contactBox.values
        .where((c) => c.isDeleted)
        .map((c) => c.id)
        .toList();
  }


Future<void> fetchContacts() async {
  if (isFetching.value) return;
  isFetching.value = true;

  try {
    // ✅ Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    final user = authController.firebaseUser.value;
    if (user == null) throw Exception('User not authenticated');

    if (hasInternet) {
      // 🔹 Online: Fetch ALL contacts from Firestore on app open
      Query<Map<String, dynamic>> query =
          firestore.collection('contacts');

      final snapshot = await query.get();
      final deletedIds = _getLocallyDeletedIds();
      
      // Convert to contacts
      final firestoreContacts = snapshot.docs
          .map((doc) => Contact.fromMap(doc.id, doc.data()))
          .where((c) => !deletedIds.contains(c.id))
          .toList();

      // 🔹 Load local contacts
      var localContacts = contactBox.values.toList();

      // 🔹 Ensure all contacts have isDeleted field (for backward compatibility)
      // Batch update for faster performance
      final contactsToUpdate = <String, Contact>{};
      for (final contact in localContacts) {
        if (contact.isDeleted is! bool) {
          final fixedContact = contact.copyWith(isDeleted: false);
          contactsToUpdate[contact.id] = fixedContact;
        }
      }
      if (contactsToUpdate.isNotEmpty) {
        await contactBox.putAll(contactsToUpdate);
        localContacts = contactBox.values.toList();
      }

      // 🔹 Keep local-only contacts
      final localOnlyContacts = localContacts
          .where((local) =>
              !local.isSynced ||
              !firestoreContacts.any((f) => f.id == local.id))
          .toList();

      // 🔹 Filter out deleted contacts
      final activeContacts = [...firestoreContacts, ...localOnlyContacts]
          .where((c) => !c.isDeleted)
          .toList();

      // 🔹 Load deleted contacts from Hive
      deletedContacts.value = localContacts
          .where((c) => c.isDeleted)
          .toList();

      // 🔹 Update Hive cache efficiently (batch operation)
      final cachesToUpdate = <String, Contact>{};
      for (var contact in firestoreContacts) {
        final local = contactBox.get(contact.id);
        // ❌ Never overwrite a locally deleted contact
        if (local == null || !local.isDeleted) {
          cachesToUpdate[contact.id] = contact;
        }
      }
      if (cachesToUpdate.isNotEmpty) {
        await contactBox.putAll(cachesToUpdate);
      }

      // 🔹 Remove deleted Firestore contacts (but keep local deleted ones)
      final idsToDelete = <String>[];
      for (var localContact in localContacts) {
        if (localContact.isSynced &&
            !localContact.isDeleted &&
            !firestoreContacts.any((f) => f.id == localContact.id)) {
          idsToDelete.add(localContact.id);
        }
      }
      if (idsToDelete.isNotEmpty) {
        await contactBox.deleteAll(idsToDelete);
      }

      contacts.value = activeContacts;

      // Save pagination state
      if (snapshot.docs.isNotEmpty) lastVisible = snapshot.docs.last;

      Get.snackbar('Sync Complete', 'Loaded ${activeContacts.length} contacts from Cloud.');
    } else {
      // 🔹 Offline: load from local Hive
      var allLocal = contactBox.values.toList();
      
      // 🔹 Ensure all contacts have isDeleted field (for backward compatibility)
      for (int i = 0; i < allLocal.length; i++) {
        final contact = allLocal[i];
        if (contact.isDeleted is! bool) {
          final fixedContact = contact.copyWith(isDeleted: false);
          await contactBox.put(contact.id, fixedContact);
          allLocal[i] = fixedContact;
        }
      }
      
      contacts.value = allLocal.where((c) => !c.isDeleted).toList();
      deletedContacts.value = allLocal.where((c) => c.isDeleted).toList();
      Get.snackbar('Offline Mode', 'Loaded contacts from local storage.');
    }
  } catch (e) {
    // 🔹 Fallback to local data if any error occurs
    var allLocal = contactBox.values.toList();
    
    // 🔹 Ensure all contacts have isDeleted field (for backward compatibility)
    for (int i = 0; i < allLocal.length; i++) {
      final contact = allLocal[i];
      if (contact.isDeleted is! bool) {
        final fixedContact = contact.copyWith(isDeleted: false);
        await contactBox.put(contact.id, fixedContact);
        allLocal[i] = fixedContact;
      }
    }
    
    contacts.value = allLocal.where((c) => !c.isDeleted).toList();
    deletedContacts.value = allLocal.where((c) => c.isDeleted).toList();
    Get.snackbar('Offline Mode', 'Loaded contacts from local storage.');
  } finally {
    filterContacts();
    isFetching.value = false;
  }
}

  Future<void> syncSelectedContacts() async {
  // ✅ Restrict to admins only
  if (authController.userRole.value != 'admin') {
    Get.snackbar(
      'Permission Denied',
      'Only admins can sync contacts to Firebase.',
    );
    return;
  }

  final List<Contact> unsyncedContacts = selectedContacts
      .where((c) => !c.isSynced && c.ownerId.isNotEmpty)
      .toList();

  if (unsyncedContacts.isEmpty) {
    Get.snackbar('No Changes', 'All selected contacts are already synced.');
    return;
  }

  int successCount = 0;
  List<String> failedContactNames = [];

  for (final contact in unsyncedContacts) {
    try {
      await syncContactToFirestore(contact);
      successCount++;
    } catch (e) {
      failedContactNames.add(contact.name);
      print('Sync failed for contact [${contact.id}]: $e');
    }
  }

  if (successCount > 0) {
    Get.snackbar(
      'Sync Complete',
      '$successCount contact(s) synced successfully.',
    );
  }

  if (failedContactNames.isNotEmpty) {
    Get.snackbar(
      'Sync Failed',
      'Could not sync: ${failedContactNames.join(', ')}',
      duration: const Duration(seconds: 5),
    );
  }
}


  Future<void> loadMoreContacts() async {
    if (loadingMore.value || lastVisible == null) return;
    loadingMore.value = true;

    try {
      // ✅ Check internet connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult != ConnectivityResult.none;

      if (!hasInternet) {
        // 🔹 Offline mode: Load remaining local contacts from Hive
        var allLocal = contactBox.values.toList();
        final activeLocal = allLocal.where((c) => !c.isDeleted).toList();
        
        // Show only new contacts not already in the current list
        final newLocalContacts = activeLocal
            .where((c) => !contacts.any((existing) => existing.id == c.id))
            .toList();

        if (newLocalContacts.isNotEmpty) {
          contacts.addAll(newLocalContacts);
          filterContacts();
          Get.snackbar(
            'Offline Mode',
            'Loaded ${newLocalContacts.length} more local contacts',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'No More Contacts',
            'All available local contacts are loaded. Go online to sync more.',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        }
        return;
      }

      // 🔹 Online: Fetch from Firestore
      final userId = authController.firebaseUser.value?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await firestore
          .collection('contacts')
          .where('ownerId', whereIn: [userId, 'admin'])
          .startAfterDocument(lastVisible!)
          .limit(pageSize)
          .get();

      final newContacts = snapshot.docs
          .map((doc) => Contact.fromMap(doc.id, doc.data()))
          .toList();

      // Batch update Hive for better performance
      final batchUpdates = <String, Contact>{};
      for (var contact in newContacts) {
        if (!contacts.any((c) => c.id == contact.id)) {
          contacts.add(contact);
          batchUpdates[contact.id] = contact;
        }
      }
      if (batchUpdates.isNotEmpty) {
        await contactBox.putAll(batchUpdates);
      }

      if (snapshot.docs.isNotEmpty) lastVisible = snapshot.docs.last;

      if (newContacts.isEmpty) {
        Get.snackbar(
          'No More Contacts',
          'You have loaded all available contacts.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
        );
      }

      filterContacts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load more contacts: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      loadingMore.value = false;
    }
  }


  Future<void> addContact(Contact contact) async {
    try {
      final user = authController.firebaseUser.value;
      if (user == null) throw Exception('User not authenticated');

      // Determine who owns the contact (admin or user)
      final ownerId = authController.userRole.value == 'admin'
          ? 'admin'
          : user.uid;

      // Generate a local-only unique ID using uuid
      final localId = const Uuid().v4();

      // Create a local version of the contact
      final localContact = contact.copyWith(
        id: localId,
        ownerId: ownerId,
        isSynced: false, // Always false since it's not synced yet
      );

      // ✅ Save to local Hive storage
      await contactBox.put(localId, localContact);

      // ✅ Update in-memory list (reactive)
      contacts.add(localContact);
      filterContacts();

      // ✅ Notify user
      Get.snackbar(
        'Saved Offline',
        'Contact saved locally to your device.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add contact: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  Future<void> editContact({
    required Contact contact,
    required String name,
    required String phone,
    required String? landline,
    required String email,
    List<String>? phoneNumbers,
    List<String>? landlineNumbers,
    List<String>? emailAddresses,
    Map<String, String>? customFields,
    String? whatsapp,
    String? facebook,
    String? instagram,
    String? youtube,
  }) async {
    final updatedContact = contact.copyWith(
      name: name,
      phone: phone,
      landline: landline ?? contact.landline,
      email: email,
      phoneNumbers: phoneNumbers ?? contact.phoneNumbers,
      landlineNumbers: landlineNumbers ?? contact.landlineNumbers,
      emailAddresses: emailAddresses ?? contact.emailAddresses,
      facebook: facebook ?? contact.facebook,
      whatsapp: whatsapp ?? contact.whatsapp,
      instagram: instagram ?? contact.instagram,
      youtube: youtube ?? contact.youtube,
      customFields: customFields ?? contact.customFields,
      isSynced: false,
    );

    updateContact(updatedContact);
    await contactBox.put(updatedContact.id, updatedContact);
    filterContacts();

    // Auto-sync edit (awaited)
    await syncContactToFirestore(updatedContact);
  }


  Future<void> deleteContact(Contact contact) async {
  // Mark as deleted instead of removing
  final deletedContact = contact.copyWith(isDeleted: true);
  contacts.removeWhere((c) => c.id == contact.id);
  deletedContacts.add(deletedContact);
  await contactBox.put(contact.id, deletedContact);
  filterContacts();
}

  Future<void> restoreContact(Contact contact) async {
    // Unmark as deleted
    final restoredContact = contact.copyWith(isDeleted: false);
    deletedContacts.removeWhere((c) => c.id == contact.id);
    contacts.add(restoredContact);
    await contactBox.put(contact.id, restoredContact);
    filterContacts();
  }
  Future<void> permanentlyDeleteContact(Contact contact) async {
    // Permanently remove from database
    deletedContacts.removeWhere((c) => c.id == contact.id);
    await contactBox.delete(contact.id);
    
    // Also delete from Firestore if it was synced
    if (contact.isSynced) {
      try {
        await firestore.collection('contacts').doc(contact.id).delete();
      } catch (e) {
        print('Error deleting from Firestore: $e');
      }
    }
    filterContacts();
  }

  Future<void> loadContactDetails(String userId) async {
    try {
      // Step 1: Fetch the user's username from the `users` collection
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final username = userSnapshot.data()?['username'];

        if (username != null && username.toString().trim().isNotEmpty) {
          // Step 2: Search in `contacts` collection where `name` == `username`
          final querySnapshot = await FirebaseFirestore.instance
              .collection('contacts')
              .where('name', isEqualTo: username)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            contactData.value = querySnapshot.docs.first.data();
          } else {
            contactData.clear();
            print('No contact found for username: $username');
          }
        }
      }
    } catch (e) {
      print('Error loading contact details: $e');
    }
  }

  Future<void> toggleFavorite(Contact contact) async {
    final updatedStatus = !contact.isFavorite;

    final updatedContact = contact.copyWith(
      isFavorite: updatedStatus,
    );

    final idx = contacts.indexWhere((c) => c.id == contact.id);
    if (idx != -1) {
      contacts[idx] = updatedContact;
    }
    await contactBox.put(updatedContact.id, updatedContact);
    filterContacts();
  }

  Future<void> syncContactToFirestore(Contact contact) async {
    try {
      // ✅ Restrict to admins only
      if (authController.userRole.value != 'admin') {
        Get.snackbar(
          'Permission Denied',
          'Only admins can sync contacts to Firebase.',
        );
        return;
      }

      // 🔹 Determine if this is a new or existing contact in Firestore
      // Use uuid v4 length (36) to check for local vs remote, or check isSynced
      final isLocal = !contact.isSynced;
      final docRef = !isLocal
          ? firestore.collection('contacts').doc(contact.id)
          : null;

      if (docRef == null) {
        // 🔹 Add new contact to Firestore
        final newDoc = await firestore.collection('contacts').add(
              contact.copyWith(ownerId: 'admin', isSynced: true).toMap(),
            );

        final synced = contact.copyWith(
          id: newDoc.id,
          ownerId: 'admin',
          isSynced: true,
        );

        contacts.removeWhere((c) => c.id == contact.id);
        contacts.add(synced);
        await contactBox.delete(contact.id);
        await contactBox.put(synced.id, synced);
      } else {
        // 🔹 Update existing contact in Firestore
        await docRef.set(
          contact.copyWith(ownerId: 'admin', isSynced: true).toMap(),
        );

        final synced = contact.copyWith(ownerId: 'admin', isSynced: true);
        final idx = contacts.indexWhere((c) => c.id == contact.id);
        if (idx != -1) {
          contacts[idx] = synced;
        }
        await contactBox.put(synced.id, synced);
      }

      filterContacts();
      Get.snackbar('Success', 'Contact synced to Firebase as admin!');
    } catch (e) {
      print('Sync failed for contact ${contact.id}: $e');
      Get.snackbar('Error', 'Failed to sync contact: $e');
    }
  }

/// ---------------------------------------------------------------------------
///  FIXED UNSYNC / UNPUBLISH LOGIC
/// ---------------------------------------------------------------------------

  Future<Contact> _unsyncContactAndReturn(Contact contact) async {
    try {
      // Delete from Firestore if synced
      if (contact.isSynced) {
        await firestore.collection('contacts').doc(contact.id).delete();
      }

      // Create a new local ID using uuid
      final String localId = const Uuid().v4();

      // Create local-only unsynced version
      final Contact unsynced = contact.copyWith(
        id: localId,
        isSynced: false,
        ownerId: authController.firebaseUser.value?.uid ?? '',
      );

      // Replace in-memory version
      contacts.removeWhere((c) => c.id == contact.id);
      contacts.add(unsynced);

      // Replace in Hive
      await contactBox.delete(contact.id);
      await contactBox.put(localId, unsynced);

      filterContacts();
      return unsynced;
    } catch (e) {
      print('Unsync failed for contact ${contact.id}: $e');
      rethrow;
    }
  }

Future<void> unsyncContact(Contact contact) async {
  try {
    final Contact updated = await _unsyncContactAndReturn(contact);

    // Update selection set
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
      selectedContacts.add(updated);
    }

    Get.snackbar('Success', 'Contact "${contact.name}" was unpublished.');
  } catch (e) {
    Get.snackbar('Error', 'Failed to unpublish contact: $e');
  }
}

Future<void> unsyncSelectedContacts() async {
  final List<Contact> toUnsync =
      selectedContacts.where((c) => c.isSynced).toList();

  if (toUnsync.isEmpty) {
    Get.snackbar('No Changes', 'All selected contacts are already local only.');
    return;
  }

  int successCount = 0;
  List<String> failed = [];

  for (final contact in toUnsync) {
    try {
      final Contact updated = await _unsyncContactAndReturn(contact);

      // Update selection set
      selectedContacts.remove(contact);
      selectedContacts.add(updated);

      successCount++;
    } catch (e) {
      failed.add(contact.name);
    }
  }

  if (successCount > 0) {
    Get.snackbar('Unpublish Complete',
        '$successCount contact(s) successfully unpublished.');
  }

  if (failed.isNotEmpty) {
    Get.snackbar('Unpublish Failed', 'Could not unpublish: ${failed.join(', ')}');
  }
}



  Future<void> addContactToFirebaseIfAdmin(Contact contact) async {
    final role = authController.userRole.value;
    if (role == 'admin') {
      try {
        final docRef = await firestore
            .collection('contacts')
            .add(contact.copyWith(ownerId: 'admin', isSynced: true).toMap());
        final addedContact =
            contact.copyWith(id: docRef.id, ownerId: 'admin', isSynced: true);
        contacts.add(addedContact);
        await contactBox.put(addedContact.id, addedContact);
        filterContacts();
        Get.snackbar('Success', 'Contact added to Firebase as admin!');
      } catch (e) {
        Get.snackbar('Error', 'Failed to add contact to Firebase: $e');
      }
    } else {
      Get.snackbar('Permission Denied',
          'Only admins can add contacts directly to Firebase.');
    }
  }

  Future<void> deleteContactFromFirebaseIfAdmin(Contact contact) async {
    final role = authController.userRole.value;
    if (role == 'admin') {
      try {
        await firestore.collection('contacts').doc(contact.id).delete();
        contacts.removeWhere((c) => c.id == contact.id);
        await contactBox.delete(contact.id);
        filterContacts();
        Get.snackbar('Success', 'Contact deleted from Cloud!');
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete contact from Cloud: $e');
      }
    } else {
      Get.snackbar('Permission Denied',
          'Only admins can delete contacts from Cloud.');
    }
  }

  Future<void> updateContactToFirebaseIfAdmin(Contact contact) async {
    final role = authController.userRole.value;
    if (role == 'admin') {
      try {
        await firestore.collection('contacts').doc(contact.id).set(
              contact.copyWith(ownerId: 'admin', isSynced: true).toMap(),
            );

        final updatedContact =
            contact.copyWith(ownerId: 'admin', isSynced: true);
        contacts[contacts.indexWhere((c) => c.id == updatedContact.id)] =
            updatedContact;
        await contactBox.put(updatedContact.id, updatedContact);
        filterContacts();
        Get.snackbar('Success', 'Contact updated in Cloud as admin!');
      } catch (e) {
        Get.snackbar('Error', 'Failed to update contact in Cloud: $e');
      }
    } else {
      Get.snackbar(
          'Permission Denied', 'Only admins can update contacts in Cloud.');
    }
  }

  bool isAdmin() {
    return authController.userRole.value == 'admin';
  }

  void filterContacts() {
    if (searchQuery.value.isEmpty) {
      filteredContacts.value = contacts;
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredContacts.value = contacts.where((contact) {
        // Search in all string fields
        bool matches = false;
        if (contact.name.toLowerCase().contains(query)) matches = true;
        if (contact.phone.toLowerCase().contains(query)) matches = true;
        if ((contact.landline ?? '').toLowerCase().contains(query)) matches = true;
        if (contact.email.toLowerCase().contains(query)) matches = true;
        if ((contact.whatsapp ?? '').toLowerCase().contains(query)) matches = true;
        if ((contact.facebook ?? '').toLowerCase().contains(query)) matches = true;
        if ((contact.instagram ?? '').toLowerCase().contains(query)) matches = true;
        if ((contact.youtube ?? '').toLowerCase().contains(query)) matches = true;
        if ((contact.website ?? '').toLowerCase().contains(query)) matches = true;
        // Search in lists
        if (contact.phoneNumbers.any((p) => p.toLowerCase().contains(query))) matches = true;
        if (contact.landlineNumbers.any((l) => l.toLowerCase().contains(query))) matches = true;
        if (contact.emailAddresses.any((e) => e.toLowerCase().contains(query))) matches = true;
        // Search in custom fields
        if (contact.customFields.values.any((v) => v.toLowerCase().contains(query))) matches = true;
        return matches;
      }).toList();
    }

    filteredContacts.sort((a, b) => a.name.compareTo(b.name));

    final Map<String, List<Contact>> grouped = {};
    for (var contact in filteredContacts) {
      final name = contact.name.trim();
      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '#';
      grouped.putIfAbsent(firstLetter, () => []).add(contact);
    }

    groupedContacts.value = grouped;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterContacts();
  }

  void updateContact(Contact updatedContact) {
    final index =
        contacts.indexWhere((contact) => contact.id == updatedContact.id);
    if (index != -1) {
      contacts[index] = updatedContact;
      filterContacts();
    }
  }

  //profilecontroller

  Future<void> saveOrUpdateContact(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    data['ownerId'] = user.uid;

    final String? name = data['name'] as String?;
    final String? email = data['email'] as String?;
    final String? phone = data['phone'] as String?;

    if (name == null || name.trim().isEmpty) {
      throw Exception('Name is required');
    }

    try {
      // Try to find existing contact in Hive by ownerId and name
      Contact? existing;
      try {
        existing = contactBox.values.firstWhere(
          (c) => c.ownerId == user.uid && c.name == name,
        );
      } catch (e) {
        existing = null;
      }

      if (existing != null) {
        // Update existing contact
        final updated = existing.copyWith(
          name: name,
          email: email ?? existing.email,
          phone: phone ?? existing.phone,
          isSynced: false,
        );
        await contactBox.put(updated.id, updated);
        updateContact(updated);
      } else {
        // Add new contact
        final localId = const Uuid().v4();
        final newContact = Contact.fromMap(localId, {
          ...data,
          'id': localId,
          'isSynced': false,
        });

        await contactBox.put(localId, newContact);
        contacts.add(newContact);
      }

      filterContacts();

      // Update minimal profile fields in Firestore 'users' collection (only username since email may be null)
      final profileUpdateData = {
        'username': name,
      };
      if (email != null && email.trim().isNotEmpty) {
        profileUpdateData['email'] = email;
      }
      await firestore
          .collection('users')
          .doc(user.uid)
          .update(profileUpdateData);
    } catch (e) {
      throw Exception('Failed to save or update contact: $e');
    }
  }
  

  Future<void> deleteContactByName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final contactsRef = firestore.collection('contacts');
    final query = await contactsRef
        .where('ownerId', isEqualTo: user.uid)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await contactsRef.doc(docId).delete();

      await firestore.collection('users').doc(user.uid).update({
        'phone': FieldValue.delete(),
        'email': FieldValue.delete(),
        'facebook': FieldValue.delete(),
        'whatsapp': FieldValue.delete(),
        'instagram': FieldValue.delete(),
        'youtube': FieldValue.delete(),
      });
    } else {
      throw Exception('Contact not found for deletion');
    }
  }

  void toggleSelection(Contact contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
    isSelectionMode.value = selectedContacts.isNotEmpty;
  }

  void clearSelection() {
    selectedContacts.clear();
    isSelectionMode.value = false;
  }

  void shareSelectedContacts() {
    final contactDetails = selectedContacts
        .map((contact) => 'Name: ${contact.name}, Phone: ${contact.phone}')
        .join('\n');
    Share.share('Selected Contacts:\n$contactDetails');
  }
}

