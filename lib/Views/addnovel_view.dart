import 'package:flutter/material.dart';
import '../models/genre.dart';
import '../services/genre_service.dart';
import 'home_view.dart';

class AddNovelView extends StatefulWidget {
  const AddNovelView({super.key});

  @override
  State<AddNovelView> createState() => _AddNovelViewState();
}

class _AddNovelViewState extends State<AddNovelView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _coverUrl;
  List<Genre> _genres = [];
  List<Genre> _selectedGenres = []; // nhiều thể loại đã chọn

  final GenreService _genreService = GenreService();

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _genreService.getGenres();
    setState(() {
      _genres = genres;
    });
  }

  Future<void> _addGenre(String name) async {
    final newGenre = await _genreService.addGenre(name);
    setState(() {
      _genres.add(newGenre);
      _selectedGenres.add(newGenre); // chọn ngay thể loại vừa thêm
    });
  }

  Future<void> _saveNovel() async {
    if (!_formKey.currentState!.validate() || _selectedGenres.isEmpty) return;

    final supabase = _genreService.supabase;
    // Insert novel trước
    final novel = await supabase
        .from('novels')
        .insert({
      'title': _titleController.text,
      'author': _authorController.text,
      'description': _descriptionController.text,
      'cover_url': _coverUrl ?? '',
      'user_id': supabase.auth.currentUser?.id,
    })
        .select()
        .single();

    // Insert các thể loại liên kết vào bảng trung gian novel_genres
    for (var g in _selectedGenres) {
      await supabase.from('novel_genres').insert({
        'novel_id': novel['id'],
        'genre_id': g.id,
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
  }

  void _showAddGenreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm thể loại mới"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nhập tên thể loại"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _addGenre(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng truyện"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Hình ảnh
              GestureDetector(
                onTap: () {
                  // TODO: chọn ảnh từ gallery
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: _coverUrl == null
                      ? const Icon(Icons.add_a_photo, size: 50)
                      : Image.network(_coverUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),

              // Tên truyện
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Tên truyện"),
                validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập tên truyện" : null,
              ),

              // Tác giả
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: "Tên tác giả"),
              ),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Dropdown chọn thể loại + nút thêm
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Genre>(
                      items: _genres.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && !_selectedGenres.contains(val)) {
                          setState(() {
                            _selectedGenres.add(val);
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: "Chọn thể loại"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddGenreDialog,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Hiển thị các thể loại đã chọn
              Wrap(
                spacing: 8,
                children: _selectedGenres.map((g) {
                  return Chip(
                    label: Text(g.name),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        _selectedGenres.remove(g);
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveNovel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Đăng truyện"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}