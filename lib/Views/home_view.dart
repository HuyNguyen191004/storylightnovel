import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel.dart';
import 'login_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // Dữ liệu giả (sau này thay bằng API)
  List<Novel> get novels => [
    Novel(
      id: 1,
      title: 'Re:Zero',
      author: 'Tappei Nagatsuki',
      coverUrl:
      'https://upload.wikimedia.org/wikipedia/en/6/60/Re_Zero_kara_Hajimeru_Isekai_Seikatsu_light_novel_volume_1_cover.jpg',
    ),
    Novel(
      id: 2,
      title: 'Sword Art Online',
      author: 'Reki Kawahara',
      coverUrl:
      'https://upload.wikimedia.org/wikipedia/en/3/3c/Sword_Art_Online_light_novel_volume_1_cover.jpg',
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Novel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: novels.length,
        itemBuilder: (context, index) {
          final novel = novels[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Image.network(
                novel.coverUrl,
                width: 50,
                fit: BoxFit.cover,
              ),
              title: Text(novel.title),
              subtitle: Text(novel.author),
              onTap: () {
                // Sau này mở trang chi tiết truyện
              },
            ),
          );
        },
      ),
    );
  }
}
