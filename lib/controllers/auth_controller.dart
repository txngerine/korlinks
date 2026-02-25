import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive user state
  final Rxn<User> firebaseUser = Rxn<User>();
  // start empty so app doesn't assume a logged-in user on startup
  final RxString userRole = ''.obs;
  final RxString username = ''.obs;
  final RxString userEmail = ''.obs;
  final RxBool isPasswordHidden = true.obs;
  // Phone auth helpers
  String? _verificationId;
  int? _resendToken;

  // -------------------- LIFECYCLE --------------------

  @override
  void onInit() {
    super.onInit();
    ever(firebaseUser, _handleAuthChanged);
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      Get.offAllNamed('/login');
      return;
    }

    // If the current user is an anonymous (guest) account that was
    // previously persisted, sign them out so the app shows the login screen.
    if (user.isAnonymous) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('Failed to sign out anonymous user: $e');
      }
      Get.offAllNamed('/login');
      return;
    }

    await _loadUserData(user.uid);
    Get.offAllNamed('/home');
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      userRole.value = data['role'] ?? 'user';
      username.value = data['username'] ?? '';
      userEmail.value = data['email'] ?? '';
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  // -------------------- UI HELPERS --------------------

  void togglePasswordVisibility() {
    isPasswordHidden.toggle();
  }

  void _showSnackbar(String message) {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------- USER DATA --------------------

  // -------------------- AUTH --------------------

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email and password required');
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_mapAuthError(e));
    }
  }

  /// ✅ LOGIN WITH USERNAME (FIXED)
  Future<void> loginWithUsername(String inputUsername, String password) async {
    if (inputUsername.isEmpty || password.isEmpty) {
      _showSnackbar('Username and password required');
      return;
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: inputUsername)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnackbar('Username not found');
        return;
      }

      final email = query.docs.first.data()['email'];
      if (email == null || email.toString().isEmpty) {
        _showSnackbar('No email linked to username');
        return;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_mapAuthError(e));
    }
  }

  Future<void> signup(
    String email,
    String password,
    String role,
    String usernameInput,
  ) async {
    // username, password and role are required; email is optional
    if (password.isEmpty || role.isEmpty || usernameInput.isEmpty) {
      _showSnackbar('Username, password and role are required');
      return;
    }

    // Ensure username is unique in Firestore
    try {
      final existing = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameInput)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnackbar('Username already taken');
        return;
      }
    } catch (e) {
      // Non-fatal; proceed but warn
      _showSnackbar('Failed to validate username uniqueness');
      return;
    }

    // If email is empty, generate a synthetic email based on username
    String emailToUse = email.trim();
    if (emailToUse.isEmpty) {
      final sanitized = usernameInput
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final local = sanitized.isEmpty
          ? 'user_${DateTime.now().millisecondsSinceEpoch}'
          : sanitized;
      emailToUse = '$local@korlinks.app';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': emailToUse,
        'username': usernameInput,
        'role': role,
      });
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_mapAuthError(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!GetUtils.isEmail(email)) {
      _showSnackbar('Enter a valid email');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackbar('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_mapAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // -------------------- PROFILE --------------------

  Future<void> editProfile({
    required String updatedUsername,
    required String updatedEmail,
    String? updatedRole,
  }) async {
    if (firebaseUser.value == null) return;

    try {
      final uid = firebaseUser.value!.uid;

      final data = {
        'username': updatedUsername,
        'email': updatedEmail,
      };

      if (updatedRole != null && isAdmin) {
        data['role'] = updatedRole;
      }

      await _firestore.collection('users').doc(uid).update(data);

      username.value = updatedUsername;
      userEmail.value = updatedEmail;
      if (updatedRole != null) userRole.value = updatedRole;

      _showSnackbar('Profile updated');
    } catch (e) {
      _showSnackbar('Profile update failed');
    }
  }

  Future<void> deleteProfile() async {
    try {
      final uid = firebaseUser.value!.uid;

      await _firestore.collection('users').doc(uid).delete();
      await firebaseUser.value!.delete();

      Get.offAllNamed('/login');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackbar('Please login again');
      } else {
        _showSnackbar(e.message ?? 'Delete failed');
      }
    }
  }

  // -------------------- PHONE AUTH --------------------

  Future<void> sendPhoneCode(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCred = await _auth.signInWithCredential(credential);
            if (userCred.user != null) await _ensureUserDoc(userCred.user!);
          } catch (_) {
            // ignore sign-in errors from auto retrieval
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar(_mapAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _showSnackbar('Verification code sent');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showSnackbar('Failed to send verification code');
    }
  }

  Future<void> verifySmsCode(String smsCode) async {
    if (_verificationId == null) {
      _showSnackbar('No verification in progress');
      return;
    }

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCred = await _auth.signInWithCredential(cred);
      if (userCred.user != null) {
        await _ensureUserDoc(userCred.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_mapAuthError(e));
    } catch (e) {
      _showSnackbar('Verification failed');
    }
  }

  Future<void> _ensureUserDoc(User user) async {
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'phone': user.phoneNumber ?? '',
          'username': user.phoneNumber ?? '',
          'role': 'user',
          'email': user.email ?? '',
        });
      }
    } catch (_) {
      // non-fatal: user can still sign in even if doc write fails
    }
  }

  // -------------------- ADMIN --------------------

  bool get isAdmin => userRole.value == 'admin';

  Future<void> changeUserRole(String userId, String newRole) async {
    if (!isAdmin) {
      _showSnackbar('Unauthorized');
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      _showSnackbar('Role updated');
    } catch (e) {
      _showSnackbar('Failed to update role');
    }
  }

  // -------------------- ERROR MAP --------------------

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-not-found':
        return 'User not found';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Weak password';
      case 'network-request-failed':
        return 'Network error';
      default:
        return e.message ?? 'Authentication error';
    }
  }
}

