import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UserInformationView extends StatefulWidget {
  const UserInformationView({super.key});

  @override
  State<UserInformationView> createState() => _UserInformationViewState();
}

class _UserInformationViewState extends State<UserInformationView> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController(); // Mật khẩu cũ
  final _newPasswordController = TextEditingController(); // Mật khẩu mới

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _auth.currentUser?.displayName ?? "";
  }

  // --- HÀM UPLOAD ẢNH LÊN CLOUDINARY ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        String cloudName = "dzytgqs3e"; // Thay bằng cloud_name của bạn
        String uploadPreset = "StoryLightNovel"; // Thay bằng upload_preset của bạn

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
        );

        request.fields['upload_preset'] = uploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);
          String imageUrl = jsonResponse['secure_url'];

          // Cập nhật vào Firebase Auth
          await _auth.currentUser?.updatePhotoURL(imageUrl);
          setState(() {}); // Làm mới giao diện để hiện ảnh mới

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
          );
        }
      } catch (e) {
        debugPrint("Lỗi upload: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HÀM ĐỔI MẬT KHẨU (CẦN XÁC THỰC LẠI) ---
  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu mới phải ít nhất 6 ký tự")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      String email = user?.email ?? "";

      // Bước 1: Xác thực lại người dùng bằng mật khẩu cũ
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: _oldPasswordController.text,
      );

      await user?.reauthenticateWithCredential(credential);

      // Bước 2: Nếu xác thực thành công, tiến hành đổi mật khẩu
      await user?.updatePassword(_newPasswordController.text);

      _oldPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đổi mật khẩu thành công!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: Mật khẩu cũ không chính xác hoặc lỗi hệ thống")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDisplayName() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.updateDisplayName(_nameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã cập nhật biệt danh!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section 1: Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _auth.currentUser?.photoURL != null
                      ? NetworkImage(_auth.currentUser!.photoURL!)
                      : null,
                  child: _auth.currentUser?.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Section 2: Biệt danh
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Biệt danh",
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateDisplayName,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text("Lưu biệt danh"),
              ),
            ),

            const Divider(height: 50),

            // Section 3: Đổi mật khẩu
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Đổi mật khẩu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mật khẩu cũ",
                prefixIcon: const Icon(Icons.lock_open),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mật khẩu mới",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                child: const Text("Cập nhật mật khẩu"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}