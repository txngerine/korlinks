import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/clipboard_service.dart';

/// Widget that provides clipboard history access
class ClipboardHistoryButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onPasted;
  final Color? iconColor;

  const ClipboardHistoryButton({
    Key? key,
    required this.controller,
    this.onPasted,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ClipboardService>(
      init: Get.find<ClipboardService>(),
      builder: (clipboardService) {
        return IconButton(
          icon: Icon(Icons.history, color: iconColor ?? Colors.blue),
          tooltip: 'Clipboard History',
          onPressed: () => _showClipboardHistory(context, clipboardService),
        );
      },
    );
  }

  void _showClipboardHistory(BuildContext context, ClipboardService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ClipboardHistoryBottomSheet(
        clipboardService: service,
        onItemSelected: (item) {
          controller.text = item;
          onPasted?.call();
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Bottom sheet to display clipboard history
class ClipboardHistoryBottomSheet extends StatelessWidget {
  final ClipboardService clipboardService;
  final Function(String) onItemSelected;

  const ClipboardHistoryBottomSheet({
    Key? key,
    required this.clipboardService,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clipboard History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Obx(() {
                          return clipboardService.history.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Clear History',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Clear History?'),
                                        content: const Text('This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await clipboardService.clearHistory();
                                    }
                                  },
                                )
                              : const SizedBox.shrink();
                        }),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              // List
              Expanded(
                child: Obx(() {
                  final items = clipboardService.history;

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No clipboard history',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final timeAgo = _timeAgo(item.timestamp);

                      return ListTile(
                        leading: const Icon(Icons.content_paste, size: 20),
                        title: Text(
                          item.content.length > 50
                              ? '${item.content.substring(0, 50)}...'
                              : item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          timeAgo,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Copy'),
                              onTap: () => clipboardService.copyToClipboard(item.content),
                            ),
                            PopupMenuItem(
                              child: const Text('Use'),
                              onTap: () => onItemSelected(item.content),
                            ),
                          ],
                        ),
                        onTap: () => onItemSelected(item.content),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Extension to add clipboard history button to TextField/TextFormField
extension ClipboardHistoryExtension on TextEditingController {
  Widget buildWithClipboardHistory({
    required BuildContext context,
    required VoidCallback onPasted,
    Color? iconColor,
  }) {
    return ClipboardHistoryButton(
      controller: this,
      onPasted: onPasted,
      iconColor: iconColor,
    );
  }
}
