import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // Thư viện Cloudinary mới
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

  File? _selectedImage;
  List<Genre> _genres = [];
  List<Genre> _selectedGenres = [];
  bool _isSaving = false;

  final GenreService _genreService = GenreService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // --- CẤU HÌNH CLOUDINARY ---
  // Thay 'YOUR_CLOUD_NAME' và 'YOUR_UPLOAD_PRESET' bằng thông tin của bạn
  final cloudinary = CloudinaryPublic(
    'dzytgqs3e',
    'StoryLightNovel',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _genreService.getGenres();
      setState(() => _genres = genres);
    } catch (e) {
      debugPrint("Lỗi tải thể loại: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- HÀM UPLOAD LÊN CLOUDINARY THAY CHO FIREBASE STORAGE ---
  Future<String?> _uploadToCloudinary() async {
    if (_selectedImage == null) return null;
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          folder: 'novels',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl; // Trả về link ảnh https
    } catch (e) {
      debugPrint("Lỗi Cloudinary: $e");
      return null;
    }
  }

  Future<void> _addGenre(String name) async {
    try {
      final newGenre = await _genreService.addGenre(name);
      await _loadGenres();
      setState(() {
        if (!_selectedGenres.any((g) => g.id == newGenre.id)) {
          _selectedGenres.add(newGenre);
        }
      });
    } catch (e) {
      debugPrint("Lỗi thêm thể loại: $e");
    }
  }

  Future<void> _saveNovel() async {
    if (!_formKey.currentState!.validate() || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên truyện và chọn thể loại")),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh bìa")),
      );
      return;
    }

    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload ảnh lên Cloudinary
      String? coverUrl = await _uploadToCloudinary();

      if (coverUrl == null) {
        throw Exception("Không thể tải ảnh lên Cloudinary. Vui lòng kiểm tra lại cấu hình.");
      }

      // 2. Lưu thông tin Novel vào Firestore
      final docRef = await firestore.collection('novels').add({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cover_url': coverUrl,
        'user_id': user.uid,
        'genre_ids': _selectedGenres.map((g) => g.id).toList(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // 3. Lưu bảng phụ novel_genres
      WriteBatch batch = firestore.batch();
      for (var g in _selectedGenres) {
        var ref = firestore.collection('novel_genres').doc();
        batch.set(ref, {
          'novel_id': docRef.id,
          'genre_id': g.id,
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi lưu truyện: $e")),
      );
    }
  }

  void _showAddGenreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thêm thể loại mới"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ví dụ: Tiên Hiệp"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx);
                await _addGenre(controller.text.trim());
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
      appBar: AppBar(title: const Text("Đăng truyện mới"), backgroundColor: Colors.orange),
      body: _isSaving
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 15),
            Text("Đang tải ảnh lên Cloudinary và lưu dữ liệu...",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: 130,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo, size: 18),
                      label: Text(_selectedImage == null ? "Chọn ảnh bìa" : "Thay đổi ảnh"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Tên truyện *", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập tên truyện" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: "Tác giả", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Mô tả nội dung", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text("Thể loại truyện:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Genre>(
                      isExpanded: true,
                      hint: Text(_genres.isEmpty ? "Đang tải..." : "Chọn thể loại"),
                      items: _genres.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                      onChanged: (val) {
                        if (val != null && !_selectedGenres.any((e) => e.id == val.id)) {
                          setState(() => _selectedGenres.add(val));
                        }
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _showAddGenreDialog,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: Colors.orange),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _selectedGenres.map((g) => Chip(
                  label: Text(g.name),
                  onDeleted: () => setState(() => _selectedGenres.removeWhere((e) => e.id == g.id)),
                )).toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: _saveNovel,
                  child: const Text("ĐĂNG TRUYỆN NGAY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}