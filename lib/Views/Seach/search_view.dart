import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/genre.dart';
import '../../services/genre_service.dart';
import '../Home/noveldetail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenreService _genreService = GenreService();

  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  List<Genre> _selectedGenres = [];
  bool _showGenres = false;

  // --- TÌM KIẾM THEO TÊN ---
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedGenres = [];
    });

    try {
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
      setState(() => _isSearching = false);
    }
  }

  // --- LỌC THEO NHIỀU THỂ LOẠI (Nâng cao) ---
  void _filterByAdvancedGenres() async {
    if (_selectedGenres.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchController.clear();
      _searchResults = [];
      _showGenres = false;
    });

    try {
      // Tìm các novel_id chứa TẤT CẢ các thể loại đã chọn
      // Cách làm: Lấy danh sách novel cho từng thể loại, sau đó tìm phần giao
      List<Set<String>> novelIdsPerGenre = [];

      for (var genre in _selectedGenres) {
        final linkSnapshot = await _firestore
            .collection('novel_genres')
            .where('genre_id', isEqualTo: genre.id)
            .get();
        
        Set<String> ids = linkSnapshot.docs
            .map((doc) => doc.data()['novel_id'] as String)
            .toSet();
        novelIdsPerGenre.add(ids);
      }

      if (novelIdsPerGenre.isEmpty) {
        setState(() => _isSearching = false);
        return;
      }

      // Tìm phần giao (truyện phải có ĐỦ các thể loại được chọn)
      Set<String> intersectionIds = novelIdsPerGenre.first;
      for (var i = 1; i < novelIdsPerGenre.length; i++) {
        intersectionIds = intersectionIds.intersection(novelIdsPerGenre[i]);
      }

      if (intersectionIds.isEmpty) {
        setState(() => _isSearching = false);
        return;
      }

      List<String> finalIds = intersectionIds.toList();
      List<DocumentSnapshot> finalResults = [];

      // Truy vấn chi tiết (giới hạn 10 id mỗi lần truy vấn Firestore)
      for (var i = 0; i < finalIds.length; i += 10) {
        var chunk = finalIds.sublist(i, i + 10 > finalIds.length ? finalIds.length : i + 10);
        final novelSnapshot = await _firestore
            .collection('novels')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        finalResults.addAll(novelSnapshot.docs);
      }

      setState(() {
        _searchResults = finalResults;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Lỗi tìm kiếm nâng cao: $e");
      setState(() => _isSearching = false);
    }
  }

  void _showAdvancedSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tìm kiếm nâng cao", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Chọn một hoặc nhiều thể loại bạn muốn tìm", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<List<Genre>>(
                      stream: _genreService.getGenresStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final genres = snapshot.data!;
                        return SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: genres.map((genre) {
                              final isSelected = _selectedGenres.any((g) => g.id == genre.id);
                              return FilterChip(
                                label: Text(genre.name),
                                selected: isSelected,
                                selectedColor: Colors.orange.withOpacity(0.3),
                                checkmarkColor: Colors.orange,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      _selectedGenres.add(genre);
                                    } else {
                                      _selectedGenres.removeWhere((g) => g.id == genre.id);
                                    }
                                  });
                                  setState(() {}); // Cập nhật UI bên ngoài
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _filterByAdvancedGenres();
                      },
                      child: const Text("XÁC NHẬN TÌM KIẾM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm và nút nâng cao
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên truyện...',
                      prefixIcon: const Icon(Icons.search, color: Colors.orange),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _selectedGenres = [];
                          });
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
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showAdvancedSearchDialog,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.tune, color: Colors.orange),
                  ),
                )
              ],
            ),
            
            if (_selectedGenres.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 5,
                  children: _selectedGenres.map((g) => Chip(
                    label: Text(g.name, style: const TextStyle(fontSize: 10)),
                    onDeleted: () {
                      setState(() {
                        _selectedGenres.removeWhere((genre) => genre.id == g.id);
                        if (_selectedGenres.isEmpty) {
                          _searchResults = [];
                        } else {
                          _filterByAdvancedGenres();
                        }
                      });
                    },
                  )).toList(),
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _searchResults.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[200]),
                    const SizedBox(height: 10),
                    Text(
                      _selectedGenres.isNotEmpty
                          ? 'Không tìm thấy truyện nào thỏa mãn tất cả các thể loại đã chọn'
                          : 'Hãy nhập tên truyện hoặc dùng Tìm kiếm nâng cao',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final data = _searchResults[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['cover_url'] ?? '',
                          width: 55, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 55, color: Colors.grey[200],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(data['title'] ?? 'Không tiêu đề',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text("Tác giả: ${data['author'] ?? 'Ẩn danh'}",
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ),
                      onTap: () {
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
    );
  }
}