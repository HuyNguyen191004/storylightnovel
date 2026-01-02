import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reading_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử đọc truyện",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text("Vui lòng đăng nhập để xem lịch sử"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đọc truyện nào."));
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final data = historyDocs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['coverUrl'] ?? '',
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 60, color: Colors.grey, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Không rõ tên',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Đang đọc: Chương ${data['lastChapterIndex'] + 1}"),
                      Text(
                        "Lần cuối: ${_formatTimestamp(data['timestamp'])}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.orange, size: 30),
                  onTap: () {
                    // Truyền thêm cả thông tin tên và ảnh để ReadingView có thể cập nhật lại lịch sử khi lật trang
                    _continueReading(
                        context,
                        data['novelId'],
                        data['lastChapterIndex'],
                        data['title'] ?? '',
                        data['coverUrl'] ?? ''
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Vừa xong";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  // --- HÀM XỬ LÝ CHUYỂN ĐẾN CHƯƠNG ĐANG ĐỌC ---
  void _continueReading(BuildContext context, String novelId, int lastIndex, String title, String coverUrl) async {
    try {
      // 1. Hiển thị thông báo đang tải
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang tải dữ liệu truyện..."), duration: Duration(seconds: 1)),
      );

      // 2. Lấy danh sách chương từ collection novels
      final chapterSnap = await FirebaseFirestore.instance
          .collection('novels')
          .doc(novelId)
          .collection('chapters')
          .orderBy('chapter_number', descending: false)
          .get();

      if (chapterSnap.docs.isNotEmpty) {
        // 3. Chuyển đổi dữ liệu sang List<Map<String, String>>
        List<Map<String, String>> allChapters = chapterSnap.docs.map((doc) {
          final d = doc.data();
          return {
            "title": "Chương ${d['chapter_number']}: ${d['title']}",
            "content": d['content']?.toString() ?? '',
          };
        }).toList();

        // 4. Kiểm tra context còn hiệu lực không và chuyển trang
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadingView(
                chapters: allChapters,
                initialIndex: lastIndex,
                novelId: novelId,
                novelTitle: title,
                coverUrl: coverUrl,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không tìm thấy nội dung chương!")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }
}