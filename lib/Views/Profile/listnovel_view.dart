import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addchapter_view.dart';

class ListNovelView extends StatefulWidget {
  const ListNovelView({super.key});

  @override
  State<ListNovelView> createState() => _ListNovelViewState();
}

class _ListNovelViewState extends State<ListNovelView> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> _deleteNovel(String novelId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa truyện này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await firestore.collection('novels').doc(novelId).delete();

      final genreLinks = await firestore
          .collection('novel_genres')
          .where('novel_id', isEqualTo: novelId)
          .get();

      for (var doc in genreLinks.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa truyện thành công")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi xóa: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Truyện đã đăng",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('novels')
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Hệ thống đang thiết lập dữ liệu. Vui lòng thử lại sau vài phút."),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đăng truyện nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final String novelId = docs[index].id;
              final novel = docs[index].data() as Map<String, dynamic>;
              final String coverUrl = novel['cover_url']?.toString() ?? "";

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddChapterView(
                          novelId: novelId,
                          novelTitle: novel['title'] ?? 'Không tiêu đề',
                        ),
                      ),
                    );
                  },
                  leading: Container(
                    width: 50, height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: (coverUrl.isNotEmpty && coverUrl.startsWith('http'))
                          ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      )
                          : const Icon(Icons.image),
                    ),
                  ),
                  title: Text(
                    novel['title'] ?? 'Không tiêu đề',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // --- PHẦN SỐ CHƯƠNG ĐÃ ĐƯỢC THÊM TẠI ĐÂY ---
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(novel['author'] ?? 'Ẩn danh', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection('novels')
                            .doc(novelId)
                            .collection('chapters')
                            .snapshots(),
                        builder: (context, chapterSnap) {
                          if (chapterSnap.hasData) {
                            int count = chapterSnap.data!.docs.length;
                            return Text(
                              "Số chương: $count",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return const Text("...", style: TextStyle(fontSize: 12));
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteNovel(novelId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}