import 'package:get/get.dart';
import '../model/contact.dart';

class ContactListController extends GetxController {
  final RxList<Contact> contacts = <Contact>[].obs;

  /// flattened list with headers
  final RxList<dynamic> displayList = <dynamic>[].obs;

  /// map letter → list index
  final Map<String, int> alphabetIndex = {};

  void prepareDisplayList() {
    displayList.clear();
    alphabetIndex.clear();

    contacts.sort((a, b) => a.name.compareTo(b.name));

    String currentLetter = "";

    for (var contact in contacts) {
      final letter =
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "#";

      if (letter != currentLetter) {
        currentLetter = letter;

        alphabetIndex[letter] = displayList.length;

        displayList.add(letter); // header
      }

      displayList.add(contact);
    }

    displayList.refresh();
  }
}