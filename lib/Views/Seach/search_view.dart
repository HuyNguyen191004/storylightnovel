import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Home/noveldetail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Danh sách lưu kết quả tìm kiếm thực tế từ Firestore
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  // --- HÀM TÌM KIẾM THỰC TẾ TỪ FIRESTORE ---
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Tìm kiếm theo tiêu đề (Lưu ý: Firestore tìm kiếm query khá hạn chế,
      // đây là cách tìm kiếm gần đúng cơ bản)
      final snapshot = await _firestore
          .collection('novels')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Lỗi tìm kiếm: $e");
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar đồng bộ với Home và Profile
      appBar: AppBar(
        title: const Text('Tìm kiếm truyện',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thanh tìm kiếm
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên truyện cần tìm...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),

            // Kết quả tìm kiếm
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _searchResults.isEmpty
                  ? const Center(
                  child: Text('Nhập tên truyện để tìm kiếm',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final data = _searchResults[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['cover_url'] ?? '',
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 40),
                        ),
                      ),
                      title: Text(data['title'] ?? 'Không tiêu đề',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Tác giả: ${data['author'] ?? 'Ẩn danh'}"),
                      onTap: () {
                        // Chuyển sang chi tiết truyện
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NovelDetailView(
                              novelId: _searchResults[index].id,
                              novelData: data,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ĐÃ XÓA bottomNavigationBar TẠI ĐÂY
    );
  }
}