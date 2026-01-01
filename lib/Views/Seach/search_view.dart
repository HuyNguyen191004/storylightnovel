import 'package:flutter/material.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<String> _results = [];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
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

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Tạm thời tạo kết quả giả lập
    setState(() {
      _results = List.generate(
        5,
            (i) => "Kết quả ${i + 1} cho \"$query\"",
      );
    });
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
                'Tìm kiếm',
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Chưa có kết quả'))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(_results[index]),
                    ),
                  );
                },
              ),
            ),
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