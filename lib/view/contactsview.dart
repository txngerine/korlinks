// ignore_for_file: unused_local_variable, prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, deprecated_member_use, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/contact_controller.dart';
import '../controllers/group_controller.dart';
import '../model/contact.dart';
import 'addeditpage.dart';
import 'contact_detail.dart';
import 'dart:async';

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
}

class ContactsView extends StatefulWidget {
  @override
  _ContactsViewState createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final ContactController controller = Get.find<ContactController>();
  final Set<Contact> _selectedContacts = {};

  bool _isSelectionMode = false;
  bool _showNoContactsMessage = false;
  late Worker _searchDebounce;
  late Worker _filteredContactsEver;
  Contact? _expandedContact;

  @override
  void initState() {
    super.initState();
    controller.contacts.value = controller.contactBox.values.toList();
    controller.filterContacts();

    _searchDebounce = debounce(controller.searchQuery, (_) {
      controller.filterContacts();
    }, time: Duration(milliseconds: 300));

    _filteredContactsEver =
        ever(controller.filteredContacts, (List<Contact> filtered) {
      if (!mounted) return;
      setState(() {
        _showNoContactsMessage =
            filtered.isEmpty && controller.searchQuery.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    _filteredContactsEver.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await controller.fetchContacts();
    controller.filterContacts();
    setState(() {
      _selectedContacts.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
      _isSelectionMode = _selectedContacts.isNotEmpty;
    });
  }

  void _shareSelectedContacts() {
    final contactDetails = _selectedContacts
        .map((contact) => 'Name: ${contact.name}, Phone: ${contact.phone}')
        .join('\n');
    Share.share('Selected Contacts:\n$contactDetails');
  }

  void _deleteSelectedContacts() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select contacts to delete.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text(
            "Are you sure you want to delete the ${_selectedContacts.length} selected contacts?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.black))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final deletedCount = _selectedContacts.length;

      if (controller.isAdmin()) {
        for (var contact in _selectedContacts) {
          await controller.deleteContactFromFirebaseIfAdmin(contact);
        }
      } else {
        for (var contact in _selectedContacts) {
          await controller.deleteContact(contact);
        }
      }

      setState(() {
        _selectedContacts.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount contacts have been deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _formGroup() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select contacts to form a group.')));
      return;
    }

    final controllerInput = TextEditingController();
    final groupName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Group'),
        content: TextField(
          controller: controllerInput,
          decoration: InputDecoration(hintText: 'Enter group name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.black))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controllerInput.text.trim()),
              child: Text('Create', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (groupName == null || groupName.isEmpty) return;

    final groupController = Get.find<GroupController>();
    try {
      await groupController.createGroup(groupName, _selectedContacts.toList());
      setState(() {
        _selectedContacts.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$groupName" created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    }
  }

  void _markSelectedAsFavorites() {
    for (var contact in _selectedContacts) {
      controller.toggleFavorite(contact);
    }
    setState(() {
      _selectedContacts.clear();
      _isSelectionMode = false;
    });
  }

  void _messageSelectedContacts() {
    final phoneNumbers = _selectedContacts.map((c) => c.phone).join(', ');
    print('Message sent to: $phoneNumbers');
    setState(() {
      _selectedContacts.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;

    double getFontSize(double base) => isSmallScreen ? base * 0.85 : base;
    double getIconSize(double base) => isSmallScreen ? base * 0.85 : base;

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _selectedContacts.clear();
            _isSelectionMode = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: isSmallScreen ? 56 : 70,
          title: _isSelectionMode
              ? SizedBox(
                  height: isSmallScreen ? 32 : 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedContacts.length}',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: getFontSize(20)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _selectedContacts.clear();
                            _isSelectionMode = false;
                          });
                        },
                        iconSize: getIconSize(18),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: isSmallScreen ? 32 : 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
                  child: TextField(
                    onChanged: (val) => controller.searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(color: Colors.black, fontSize: getFontSize(16)),
                  ),
                ),
          backgroundColor: Colors.blue,
          actions: [
            if (_isSelectionMode) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.white),
                    onPressed: _shareSelectedContacts,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    iconSize: getIconSize(18),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteSelectedContacts,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    iconSize: getIconSize(18),
                  ),
                  IconButton(
                    icon: Icon(Icons.group, color: Colors.white),
                    onPressed: _formGroup,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    iconSize: getIconSize(18),
                  ),
                  IconButton(
                    icon: Icon(Icons.favorite, color: Colors.white),
                    onPressed: _markSelectedAsFavorites,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    iconSize: getIconSize(18),
                  ),
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.white),
                    onPressed: _messageSelectedContacts,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    iconSize: getIconSize(18),
                  ),
                  if (controller.isAdmin() && _selectedContacts.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Builder(
                        builder: (context) {
                          final allPublished = _selectedContacts.isNotEmpty &&
                              _selectedContacts.every((c) => c.isSynced == true);
                          return ElevatedButton.icon(
                            icon: Icon(
                              allPublished ? Icons.cloud_off : Icons.cloud_upload,
                              size: getIconSize(16),
                            ),
                            label: Text(
                              allPublished ? 'Unpublish' : '',
                              style: TextStyle(fontSize: getFontSize(12)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allPublished ? Colors.red : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () async {
                              if (allPublished) {
                                // Unpublish logic
                                int updatedCount = 0;
                                for (var contact in _selectedContacts) {
                                  await controller.unsyncContact(contact);
                                  updatedCount++;
                                }
                                setState(() {
                                  _selectedContacts.clear();
                                  _isSelectionMode = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$updatedCount contact(s) unpublished from Firebase.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                // Publish logic (your existing code)
                                final contactsToSync = _selectedContacts
                                    .where((c) => c.isSynced == false)
                                    .toList();
                                if (contactsToSync.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Selected contacts are already synced.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                int updatedCount = 0;
                                for (var contact in contactsToSync) {
                                  await controller.syncContactToFirestore(contact);
                                  updatedCount++;
                                }

                                setState(() {
                                  _selectedContacts.clear();
                                  _isSelectionMode = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      updatedCount > 0
                                          ? '$updatedCount published to Firebase.'
                                          : 'No contacts were updated.',
                                    ),
                                    backgroundColor: updatedCount > 0 ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: Icon(Icons.select_all, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedContacts.addAll(controller.filteredContacts);
                  });
                },
                iconSize: getIconSize(18),
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          color: Colors.blue,
          onRefresh: _onRefresh,
          child: Obx(() {
            final uniqueContacts = <String, Contact>{};
            for (var contact in controller.filteredContacts) {
              uniqueContacts[contact.id] = contact;
            }
            final filteredContacts = uniqueContacts.values.toList();

            if (filteredContacts.isEmpty && _showNoContactsMessage) {
              return ListView(
                children: [
                  SizedBox(height: screenHeight * 0.25),
                  Center(
                      child: Text("No contacts found",
                          style: TextStyle(
                              fontSize: getFontSize(18),
                              color: Colors.grey))),
                ],
              );
            }
            if (filteredContacts.isEmpty) {
              return ListView.builder(
                itemCount: 8,
                itemBuilder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListTile(
                    leading: CircleAvatar(radius: getIconSize(20)),
                    title:
                        Container(height: getFontSize(10), color: Colors.white),
                    subtitle:
                        Container(height: getFontSize(10), color: Colors.white),
                  ),
                ),
              );
            }

            final Map<String, List<Contact>> groupedContacts = {};
            for (var contact in filteredContacts) {
              final name = contact.name?.trim() ?? '';
              final char = name.isNotEmpty ? name[0].toUpperCase() : '#';
              groupedContacts.putIfAbsent(char, () => []).add(contact);
            }

            final keys = groupedContacts.keys.toList()..sort();
            final groups = keys.map((key) {
              final groupList = List<Contact>.from(groupedContacts[key]!)
                ..sort((a, b) =>
                    (a.name ?? '').compareTo(b.name ?? ''));
              return AlphabetListViewItemGroup(
                tag: key,
                children: groupList.map((contact) {
                  final isSelected = _selectedContacts.contains(contact);
                  return GestureDetector(
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(contact);
                      } else {
                        setState(() {
                          _expandedContact =
                              _expandedContact == contact ? null : contact;
                        });
                      }
                    },
                    onLongPress: () => _toggleSelection(contact),
                    child: Container(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.transparent,
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: getIconSize(20),
                              child: Text(
                                (contact.name?.isNotEmpty ?? false)
                                    ? contact.name![0].toUpperCase()
                                    : '#',
                                style:
                                    TextStyle(fontSize: getFontSize(18)),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(contact.name ?? '',
                                      style: TextStyle(
                                          fontSize: getFontSize(16))),
                                ),
                                if (contact.ownerId == 'admin' &&
                                    contact.isSynced == true) ...[
                                  SizedBox(width: 6),
                                  Icon(Icons.verified,
                                      color: Colors.blue,
                                      size: getIconSize(14)),
                                ],
                              ],
                            ),
                            subtitle: Text(
                                contact.phone?.isNotEmpty ?? false
                                    ? contact.phone
                                    : (contact.landline ?? 'No phone number'),
                                style: TextStyle(fontSize: getFontSize(14))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    contact.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: contact.isFavorite
                                        ? Colors.red
                                        : null,
                                  ),
                                  onPressed: () =>
                                      controller.toggleFavorite(contact),
                                  iconSize: getIconSize(22),
                                ),
                              ],
                            ),
                          ),
                          if (_expandedContact == contact)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 16,
                                  vertical: isSmallScreen ? 4 : 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.call,
                                        color: Colors.green,
                                        size: getIconSize(32)),
                                    onPressed: () {
                                      OppoFixLauncher.launchPhone(
                                          contact.phone);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.message,
                                        color: Colors.blue,
                                        size: getIconSize(32)),
                                    onPressed: () {
                                      OppoFixLauncher.launchSMS(
                                          contact.phone);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info,
                                        color: Colors.grey,
                                        size: getIconSize(32)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ContactDetailView(
                                                  contact: contact),
                                        ),
                                      ).then((_) => _onRefresh());
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Colors.purple,
                                        size: getIconSize(32)),
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title:
                                              Text('Confirm Deletion'),
                                          content: Text(
                                              'Delete ${contact.name}?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                child: Text('Cancel',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .black))),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                child: Text('Delete',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        if (controller.isAdmin()) {
                                          await controller
                                              .deleteContactFromFirebaseIfAdmin(
                                                  contact);
                                        } else {
                                          await controller
                                              .deleteContact(contact);
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              '${contact.name} has been deleted.'),
                                          backgroundColor: Colors.green,
                                        ));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList();

            return AlphabetListView(
              items: groups,
              options: AlphabetListViewOptions(
                overlayOptions: OverlayOptions(
                  showOverlay: true,
                  overlayBuilder: (_, tag) => Container(
                    width: isSmallScreen ? 60 : 80,
                    height: isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(tag,
                        style: TextStyle(
                            fontSize: getFontSize(40),
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                scrollbarOptions: ScrollbarOptions(
                  backgroundColor: Colors.white,
                  width: isSmallScreen ? 18 : 25,
                  symbols: keys,
                  symbolBuilder: (_, symbol, state) => Text(
                    symbol,
                    style: TextStyle(
                      fontSize: getFontSize(14),
                      fontWeight:
                          state == AlphabetScrollbarItemState.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: state ==
                              AlphabetScrollbarItemState.active
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 2 : 4),
                ),
                listOptions: ListOptions(backgroundColor: Colors.white),
              ),
            );
          }),
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _selectedContacts.clear();
                    _isSelectionMode = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditContactPage()),
                  );
                },
                child: Icon(Icons.add, size: getIconSize(18)),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
