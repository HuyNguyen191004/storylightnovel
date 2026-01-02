import 'package:flutter/material.dart';
import 'Home/home_view.dart';
import 'Seach/search_view.dart';
import 'Profile/profile_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const SearchView(),
    const HomeView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        // Chiều cao tổng thể vừa đủ để không bị tràn (Overflow)
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // Căn giữa các icon theo chiều dọc để tránh chạm biên
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.search, 0),
            _buildNavItem(Icons.home, 1),
            _buildNavItem(Icons.person, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // CHỈNH NHỎ LẠI TẠI ĐÂY:
        // Chọn: 60, Không chọn: 45 (Kích thước an toàn cho mọi màn hình)
        height: isSelected ? 60 : 45,
        width: isSelected ? 60 : 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.orange.withOpacity(0.15),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Icon(
          icon,
          // Icon cũng nhỏ lại tương ứng: 28 và 22
          size: isSelected ? 28 : 22,
          color: isSelected ? Colors.white : Colors.orange[900],
        ),
      ),
    );
  }
}