import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListNovelView extends StatefulWidget {
  const ListNovelView({super.key});

  @override
  State<ListNovelView> createState() => _ListNovelViewState();
}

class _ListNovelViewState extends State<ListNovelView> {
  List<Map<String, dynamic>> _novels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNovels();
  }

  Future<void> _loadNovels() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final response = await supabase
          .from('novels')
          .select()
          .eq('user_id', userId);

      setState(() {
        _novels = List<Map<String, dynamic>>.from(response as List);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Truyện đã đăng"),
        backgroundColor: Colors.orange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _novels.isEmpty
          ? const Center(child: Text("Bạn chưa đăng truyện nào"))
          : ListView.builder(
        itemCount: _novels.length,
        itemBuilder: (context, index) {
          final novel = _novels[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(novel['title'] ?? ''),
              subtitle: Text(novel['author'] ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: mở chi tiết truyện nếu cần
              },
            ),
          );
        },
      ),
    );
  }
}