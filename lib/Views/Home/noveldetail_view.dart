import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Profile/reading_view.dart';

class NovelDetailView extends StatelessWidget {
  final String novelId;
  final Map<String, dynamic> novelData;

  const NovelDetailView({super.key, required this.novelId, required this.novelData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(novelData['title'] ?? 'Chi tiết truyện',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Phần Header: Ảnh bìa và Thông tin cơ bản
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (novelData['cover_url'] != null && novelData['cover_url'].toString().startsWith('http'))
                        ? Image.network(
                      novelData['cover_url'],
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 120, height: 180, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    )
                        : Container(width: 120, height: 180, color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novelData['title'] ?? 'Không tiêu đề',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("Tác giả: ${novelData['author'] ?? 'Ẩn danh'}",
                            style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                        const SizedBox(height: 12),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('genres').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            List<dynamic> genreIds = novelData['genre_ids'] ?? [];
                            List<String> genreNames = snapshot.data!.docs
                                .where((doc) => genreIds.contains(doc.id))
                                .map((doc) => (doc.data() as Map<String, dynamic>)['name'].toString())
                                .toList();

                            return Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: genreNames.isNotEmpty
                                  ? genreNames.map((name) => Chip(
                                label: Text(name, style: const TextStyle(color: Colors.orange, fontSize: 11)),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.orange, width: 0.5),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList()
                                  : [const Text("Chưa có thể loại", style: TextStyle(fontSize: 12, color: Colors.grey))],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Phần Mô tả (Description)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mô tả nội dung",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    novelData['description'] ?? 'Chưa có mô tả cho bộ truyện này.',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1, indent: 16, endIndent: 16),

            // 3. Phần Danh sách chương
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Danh sách chương",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('novels')
                        .doc(novelId)
                        .collection('chapters')
                        .snapshots(),
                    builder: (context, snap) {
                      int count = snap.hasData ? snap.data!.docs.length : 0;
                      return Text("$count chương", style: const TextStyle(color: Colors.grey));
                    },
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('novels')
                  .doc(novelId)
                  .collection('chapters')
                  .orderBy('chapter_number', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("Truyện hiện chưa có chương nào.")),
                  );
                }

                List<Map<String, String>> allChapters = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    "title": "Chương ${data['chapter_number'] ?? ''}: ${data['title'] ?? ''}",
                    "content": data['content']?.toString() ?? '',
                  };
                }).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allChapters.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chap = allChapters[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Text("${index + 1}.",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      title: Text(chap['title'] ?? ''),
                      trailing: const Icon(Icons.keyboard_arrow_right, size: 20),
                      onTap: () {
                        // FIX LỖI: Truyền đầy đủ thông tin để ReadingView có thể lưu vào History
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReadingView(
                              chapters: allChapters,
                              initialIndex: index,
                              novelId: novelId,
                              novelTitle: novelData['title'] ?? 'Truyện không tên',
                              coverUrl: novelData['cover_url'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}