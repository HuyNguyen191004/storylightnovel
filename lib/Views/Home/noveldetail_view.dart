import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Profile/reading_view.dart';

class NovelDetailView extends StatefulWidget {
  final String novelId;
  final Map<String, dynamic> novelData;

  const NovelDetailView({super.key, required this.novelId, required this.novelData});

  @override
  State<NovelDetailView> createState() => _NovelDetailViewState();
}

class _NovelDetailViewState extends State<NovelDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _ratingStars = 5;

  // Controllers
  final TextEditingController _charController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _discussionController = TextEditingController();

  // Biến trạng thái cho Thảo luận
  bool _isAnonymous = false;
  int _discussionLimit = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- HÀM GỬI ĐÁNH GIÁ ---
  Future<void> _submitRating() async {
    try {
      await FirebaseFirestore.instance
          .collection('novels')
          .doc(widget.novelId)
          .collection('ratings')
          .add({
        'stars': _ratingStars,
        'character_review': _charController.text,
        'content_review': _contentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _charController.clear();
      _contentController.clear();
      setState(() { _ratingStars = 5; });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // --- HÀM GỬI THẢO LUẬN (Đã tối ưu kiểm tra biệt danh) ---
  Future<void> _submitDiscussion() async {
    if (_discussionController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      String displayName = "Người dùng ẩn danh";

      if (!_isAnonymous && user != null) {
        // Lấy từ collection 'user_information'
        final userDoc = await FirebaseFirestore.instance
            .collection('user_information')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['nickname'] != null) {
          displayName = userDoc.data()!['nickname'];
        } else {
          // Nếu chưa có biệt danh trong Firestore thì dùng email
          displayName = user.email ?? "Người dùng";
        }
      }

      await FirebaseFirestore.instance
          .collection('novels')
          .doc(widget.novelId)
          .collection('discussions')
          .add({
        'username': displayName, // Lúc này displayName đã là biệt danh từ Firestore
        'content': _discussionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'is_anonymous': _isAnonymous,
      });

      _discussionController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.novelData['title'] ?? 'Chi tiết truyện',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const Divider(thickness: 1, height: 1),
            _buildDescriptionSection(),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5), height: 8),
            _buildChapterListSection(),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5), height: 8),
            _buildSocialSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.orange.withOpacity(0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (widget.novelData['cover_url'] != null)
                ? Image.network(widget.novelData['cover_url'], width: 120, height: 180, fit: BoxFit.cover)
                : Container(width: 120, height: 180, color: Colors.grey[300], child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.novelData['title'] ?? 'Không tiêu đề',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Tác giả: ${widget.novelData['author'] ?? 'Ẩn danh'}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('novels')
                      .doc(widget.novelId)
                      .collection('ratings')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("Chưa có đánh giá", style: TextStyle(fontSize: 13, color: Colors.grey));
                    }
                    var docs = snapshot.data!.docs;
                    double totalStars = 0;
                    for (var doc in docs) {
                      totalStars += (doc.data() as Map<String, dynamic>)['stars']?.toDouble() ?? 0.0;
                    }
                    double average = totalStars / docs.length;
                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text("${average.toStringAsFixed(1)} ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("(${docs.length} đánh giá)", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildGenreChips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('genres').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        List<dynamic> genreIds = widget.novelData['genre_ids'] ?? [];
        List<String> genreNames = snapshot.data!.docs
            .where((doc) => genreIds.contains(doc.id))
            .map((doc) => (doc.data() as Map<String, dynamic>)['name'].toString())
            .toList();

        return Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: genreNames.map((name) => Chip(
            label: Text(name, style: const TextStyle(color: Colors.orange, fontSize: 11)),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.orange, width: 0.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        );
      },
    );
  }

  Widget _buildRatingTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chấm điểm cho truyện:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _ratingStars = index + 1),
                icon: Icon(index < _ratingStars ? Icons.star : Icons.star_border, color: Colors.orange, size: 30),
              )),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("GỬI ĐÁNH GIÁ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _discussionController,
            decoration: InputDecoration(
              hintText: "Viết bình luận của bạn...",
              filled: true, fillColor: Colors.grey[100],
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                onPressed: _submitDiscussion,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                activeColor: Colors.orange,
                onChanged: (val) => setState(() => _isAnonymous = val!),
              ),
              const Text("Gửi ẩn danh", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('novels')
                  .doc(widget.novelId)
                  .collection('discussions')
                  .orderBy('timestamp', descending: true)
                  .limit(_discussionLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return const Center(child: Text("Chưa có thảo luận nào"));

                return ListView(
                  children: [
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.orange[50],
                            child: const Icon(Icons.person, color: Colors.orange)
                        ),
                        title: Text(data['username'] ?? "Ẩn danh",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(data['content'] ?? "", style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    if (docs.length >= _discussionLimit)
                      TextButton(
                        onPressed: () => setState(() => _discussionLimit += 5),
                        child: const Text("Xem thêm thảo luận", style: TextStyle(color: Colors.orange)),
                      )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mô tả nội dung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(widget.novelData['description'] ?? 'Chưa có mô tả cho bộ truyện này.',
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              textAlign: TextAlign.justify),
        ],
      ),
    );
  }

  Widget _buildChapterListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Danh sách chương", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('novels').doc(widget.novelId).collection('chapters').snapshots(),
                builder: (context, snap) {
                  int count = snap.hasData ? snap.data!.docs.length : 0;
                  return Text("$count chương", style: const TextStyle(color: Colors.grey));
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('novels')
              .doc(widget.novelId)
              .collection('chapters')
              .orderBy('chapter_number', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
            final docs = snapshot.data!.docs;

            List<Map<String, String>> allChapters = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                "title": "Chương ${data['chapter_number']}: ${data['title'] ?? ''}",
                "content": data['content']?.toString() ?? '',
              };
            }).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allChapters.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(allChapters[index]['title']!),
                  trailing: const Icon(Icons.keyboard_arrow_right, size: 20),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ReadingView(
                        chapters: allChapters,
                        initialIndex: index,
                        novelId: widget.novelId,
                        novelTitle: widget.novelData['title'] ?? '',
                        coverUrl: widget.novelData['cover_url'] ?? '',
                      ),
                    ));
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: [
            const Tab(child: Text("ĐÁNH GIÁ", style: TextStyle(fontWeight: FontWeight.bold))),
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('novels')
                    .doc(widget.novelId)
                    .collection('discussions')
                    .snapshots(),
                builder: (context, snapshot) {
                  int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Text(
                      "THẢO LUẬN ($count)",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  );
                },
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        SizedBox(
          height: 550,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRatingTab(),
              _buildCommentTab(),
            ],
          ),
        ),
      ],
    );
  }
}