import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thay thế SharedPreferences bằng Firebase Auth
import 'login_view.dart';
import 'addnovel_view.dart'; // Đảm bảo file này dùng Cloudinary như đã sửa
import 'listnovel_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedIndex = 2;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy email người dùng hiện tại từ Firebase
  String get _userEmail => _auth.currentUser?.email ?? "Người dùng";

  // Hàm Logout sử dụng Firebase
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Lỗi đăng xuất: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    // Chuyển trang theo Navigation chuẩn
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/search');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildNavIcon(int index, IconData iconData) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSelected ? 65 : 50,
      width: isSelected ? 65 : 50,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]
            : [],
      ),
      child: IconButton(
        icon: Icon(
          iconData,
          size: 28,
          color: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () => _onItemTapped(index),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed, {Color? textColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor ?? Colors.black87),
        label: Text(text, style: TextStyle(fontSize: 16, color: textColor ?? Colors.black87)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          alignment: Alignment.centerLeft, // Căn lề trái cho đẹp
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar đồng bộ và KHÔNG CÓ nút quay lại
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Bỏ nút quay lại
        title: const Text(
          'Trang cá nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      // Dùng SingleChildScrollView để tránh lỗi vạch vàng khi xoay màn hình
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                _userEmail,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              _buildButton('Thông tin người dùng', Icons.info_outline, () {
                // Xử lý thông tin
              }),
              _buildButton('Đăng truyện', Icons.add_circle_outline, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddNovelView()),
                );
              }),
              _buildButton('Danh sách truyện đã đăng', Icons.list_alt, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListNovelView()),
                );
              }),
              const SizedBox(height: 20),
              _buildButton('Đăng xuất', Icons.logout, _logout, textColor: Colors.red),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavIcon(0, Icons.search),
            _buildNavIcon(1, Icons.home),
            _buildNavIcon(2, Icons.person),
          ],
        ),
      ),
    );
  }
}