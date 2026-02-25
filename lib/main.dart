// ignore_for_file: prefer_const_constructors, unnecessary_import, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:korlinks/model/contact.dart';
import 'package:korlinks/view/adminfaq.dart';
import 'controllers/auth_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/group_controller.dart';
import 'controllers/home_controller.dart';
import 'firebase_options.dart';
import 'services/in_app_update_service.dart';
import 'model/groupmodel.dart';
import 'view/faq_view.dart';
import 'view/home_view.dart';
import 'view/login_view.dart';
import 'view/signup_view.dart';
import 'view/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(GroupAdapter());
  await Hive.openBox<Contact>('contacts');
  Get.put(AuthController(), permanent: true);
  Get.put(HomeController());
  Get.put(ContactController());
  Get.put(GroupController());
  Get.put(InAppUpdateService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KorLinks',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          elevation: 0,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionColor: Colors.blue.withOpacity(0.3), 
          selectionHandleColor: Colors.blue,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.white,
          secondary: Colors.grey, 
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/signup', page: () => SignupView()),
        GetPage(name: '/home', page: () => HomeView()),
        GetPage(name: '/faq', page: () => FaqView()),
        GetPage(name: '/adminfaq', page: () => AdminFaqPage()),
      ],
    );
  }
}
