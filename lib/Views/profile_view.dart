import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_view.dart';
import 'addnovel_view.dart';
import 'listnovel_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedIndex = 2;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

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
      height: isSelected ? 70 : 50,
      width: isSelected ? 70 : 50,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]
            : [],
      ),
      child: IconButton(
        icon: Icon(
          iconData,
          size: 30,
          color: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () => _onItemTapped(index),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: const SafeArea(
            child: Center(
              child: Text(
                'Trang cá nhân',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildButton('Thông tin người dùng', () {
              // Xử lý xem thông tin người dùng
            }),
            _buildButton('Đăng truyện', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddNovelView()),
              );
            }),
            _buildButton('Danh sách truyện đã đăng', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListNovelView()),
              );
            }),

            _buildButton('Đăng xuất', _logout),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10),
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