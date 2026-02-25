// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({Key? key}) : super(key: key);

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  static const String feedbackEmail = 'korlinksteam@gmail.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final subject = _subjectController.text.trim();
    final body = '''
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}

Message:
${_messageController.text.trim()}
''';

    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (launched) {
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();

        Get.snackbar(
          'Success',
          'Email app opened. Please send your feedback.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw 'Could not open email app';
      }
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Error',
        'Unable to open email client',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Feedback'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We’d love to hear from you!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Share feedback, suggestions, or report issues.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),

              _label('Full Name'),
              _field(
                controller: _nameController,
                hint: 'Enter your full name',
                validator: (v) =>
                    v!.trim().isEmpty ? 'Name is required' : null,
              ),

              _label('Email Address'),
              _field(
                controller: _emailController,
                hint: 'Enter your email',
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),

              _label('Subject'),
              _field(
                controller: _subjectController,
                hint: 'Bug report, Feature request...',
                validator: (v) =>
                    v!.trim().isEmpty ? 'Subject is required' : null,
              ),

              _label('Message'),
              _field(
                controller: _messageController,
                hint: 'Write your feedback here...',
                maxLines: 6,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Message required';
                  if (v.length < 10) return 'Minimum 10 characters';
                  return null;
                },
              ),

              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendFeedback,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send Feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Feedback will be sent to $feedbackEmail',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: validator,
    );
  }
}
