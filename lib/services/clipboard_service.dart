import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ClipboardItem {
  final String content;
  final DateTime timestamp;

  ClipboardItem({
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ClipboardItem.fromMap(Map<String, dynamic> map) => ClipboardItem(
    content: map['content'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );
}

class ClipboardService extends GetxController {
  // Reserved for future platform-specific clipboard handling
  // static const MethodChannel _channel = MethodChannel('flutter.kloud/clipboard');
  
  late Box<String> clipboardBox;
  final RxList<ClipboardItem> history = <ClipboardItem>[].obs;
  final RxString currentClipboard = ''.obs;
  final int maxHistoryItems = 50;

  @override
  void onInit() {
    super.onInit();
    _initClipboard();
  }

  Future<void> _initClipboard() async {
    try {
      clipboardBox = await Hive.openBox<String>('clipboard_history');
      _loadHistoryFromStorage();
      await readClipboard();
    } catch (e) {
      print('ClipboardService init error: $e');
    }
  }

  /// Read current clipboard content
  Future<String> readClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      final String clipboard = data?.text ?? '';
      
      if (clipboard.isNotEmpty && clipboard != currentClipboard.value) {
        currentClipboard.value = clipboard;
        await addToHistory(clipboard);
      }
      
      return clipboard;
    } catch (e) {
      print('Error reading clipboard: $e');
      return '';
    }
  }

  /// Add item to clipboard history
  Future<void> addToHistory(String content) async {
    if (content.isEmpty) return;

    // Avoid duplicates - don't add if last item is the same
    if (history.isNotEmpty && history.first.content == content) {
      return;
    }

    final item = ClipboardItem(
      content: content,
      timestamp: DateTime.now(),
    );

    history.insert(0, item); // Add to front

    // Keep only maxHistoryItems
    if (history.length > maxHistoryItems) {
      history.removeRange(maxHistoryItems, history.length);
    }

    await _saveHistoryToStorage();
  }

  /// Copy item to clipboard
  Future<void> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      currentClipboard.value = content;
      await addToHistory(content);
      Get.snackbar(
        'Copied',
        'Text copied to clipboard',
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error copying to clipboard: $e');
      Get.snackbar('Error', 'Failed to copy to clipboard');
    }
  }

  /// Get clipboard history
  List<ClipboardItem> getHistory() => history.toList();

  /// Clear all history
  Future<void> clearHistory() async {
    history.clear();
    await clipboardBox.clear();
    Get.snackbar(
      'Cleared',
      'Clipboard history cleared',
      duration: const Duration(seconds: 1),
    );
  }

  /// Save history to local storage
  Future<void> _saveHistoryToStorage() async {
    try {
      await clipboardBox.clear();
      for (int i = 0; i < history.length; i++) {
        await clipboardBox.put(i.toString(), history[i].toMap().toString());
      }
    } catch (e) {
      print('Error saving clipboard history: $e');
    }
  }

  /// Load history from storage
  void _loadHistoryFromStorage() {
    try {
      final items = <ClipboardItem>[];
      for (var value in clipboardBox.values) {
        try {
          // Parse the stored map string back to ClipboardItem
          if (value.contains('content:') && value.contains('timestamp:')) {
            final content = value.split('content: ')[1].split(',')[0].replaceAll("'", '');
            final timestamp = value.split('timestamp: ')[1].replaceAll("'", '').replaceAll('}', '');
            items.add(ClipboardItem(
              content: content,
              timestamp: DateTime.parse(timestamp),
            ));
          }
        } catch (e) {
          print('Error parsing clipboard item: $e');
        }
      }
      history.addAll(items);
    } catch (e) {
      print('Error loading clipboard history: $e');
    }
  }

  /// Manual refresh of clipboard
  Future<void> refreshClipboard() async {
    await readClipboard();
  }
}
