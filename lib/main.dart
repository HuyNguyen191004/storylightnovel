import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Views/login_view.dart';
import 'Views/home_view.dart';
import 'Views/profile_view.dart';
import 'Views/search_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ycylywwjjigrjkgxrcan.supabase.co',
    anonKey: 'sb_publishable_RuZiY-Sdeo6s2xA_REhkGw_ylGRCcyM',
  );

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