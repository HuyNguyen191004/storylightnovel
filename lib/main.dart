// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Views/Auth/login_view.dart';
import 'Views/Home/home_view.dart';
import 'Views/Profile/profile_view.dart';
import 'Views/Seach/search_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeView(),
        '/profile': (context) => const ProfileView(),
        '/search': (context) => const SearchView(),
      },
    );
  }
}