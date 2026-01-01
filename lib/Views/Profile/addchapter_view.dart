import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddChapterView extends StatefulWidget {
  final String novelId;
  final String novelTitle;

  const AddChapterView({super.key, required this.novelId, required this.novelTitle});

  @override
  State<AddChapterView> createState() => _AddChapterViewState();
}

class _AddChapterViewState extends State<AddChapterView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isUploading = false;

  Future<void> _saveChapter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // Lưu vào sub-collection 'chapters' bên trong tài liệu của novel đó
      await FirebaseFirestore.instance
          .collection('novels')
          .doc(widget.novelId)
          .collection('chapters')
          .add({
        'chapter_number': int.parse(_numberController.text),
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thêm chương thành công!")),
        );
        Navigator.pop(context); // Quay lại sau khi thêm xong
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi lưu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm chương: ${widget.novelTitle}"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: "Chương số (ví dụ: 1)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? "Nhập số chương" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Tiêu đề chương",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Nhập tiêu đề chương" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: "Nội dung chương",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 15,
                validator: (v) => (v == null || v.isEmpty) ? "Nhập nội dung" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChapter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("ĐĂNG CHƯƠNG",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}