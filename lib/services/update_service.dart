// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final Rxn<User> firebaseUser = Rxn<User>();
//   final RxString userRole = ''.obs;
//   final RxString username = ''.obs;
//   final RxString userEmail = ''.obs;

//   bool _navigated = false; // ⛔ prevents double navigation

//   @override
//   void onInit() {
//     super.onInit();
//     firebaseUser.bindStream(_auth.authStateChanges());
//     ever(firebaseUser, _handleAuthChanged);
//   }

//   Future<void> _handleAuthChanged(User? user) async {
//     if (_navigated) return;

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (_navigated) return;
//       _navigated = true;

//       if (user == null) {
//         Get.offAllNamed('/login');
//         return;
//       }

//       if (user.isAnonymous) {
//         await _auth.signOut();
//         Get.offAllNamed('/login');
//         return;
//       }

//       await _loadUserData(user.uid);
//       Get.offAllNamed('/home');
//     });
//   }

//   Future<void> _loadUserData(String uid) async {
//     try {
//       final doc = await _firestore.collection('users').doc(uid).get();
//       if (!doc.exists) return;

//       final data = doc.data()!;
//       userRole.value = data['role'] ?? 'user';
//       username.value = data['username'] ?? '';
//       userEmail.value = data['email'] ?? '';
//     } catch (_) {}
//   }

//   // ---------------- AUTH ----------------

//   Future<void> login(String email, String password) async {
//     await _auth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<void> logout() async {
//     _navigated = false; // allow navigation again
//     await _auth.signOut();
//   }

//   bool get isAdmin => userRole.value == 'admin';
// }
