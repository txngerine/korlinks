import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
 // Import the AuthController

class EditProfilePage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  // Controllers for the input fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  EditProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pre-fill the fields with the current user details
    usernameController.text = authController.username.value;
    emailController.text = authController.userEmail.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username Field
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),

            // Role Field (Visible only if user is admin)
            Obx(
              () => authController.isAdmin
                  ? TextField(
                      controller: roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Validate inputs
                  if (usernameController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Username and email cannot be empty.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Update profile
                  await authController.editProfile(
                    updatedUsername: usernameController.text.trim(),
                    updatedEmail: emailController.text.trim(),
                    updatedRole: authController.isAdmin
                        ? roleController.text.trim()
                        : null,
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
