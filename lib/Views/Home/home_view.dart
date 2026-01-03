import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'noveldetail_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chỉnh nền của toàn bộ Scaffold sang màu xám trắng
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Trang chủ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('novels').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có truyện nào được đăng"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String coverUrl = data['cover_url']?.toString() ?? "";

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelDetailView(
                            novelId: doc.id,
                            novelData: data,
                          ),
                        ),
                      );
                    },
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ảnh bìa
                          SizedBox(
                            width: 105,
                            height: 150,
                            child: _buildCoverImage(coverUrl),
                          ),
                          // Nội dung
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? 'Không tiêu đề',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF263238),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Tác giả: ${data['author'] ?? 'Ẩn danh'}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 12),

                                  // Hàng hiển thị Số chương và Ratings từ Sub-collections
                                  Row(
                                    children: [
                                      const Icon(Icons.library_books_outlined, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      // Đếm số chương
                                      StreamBuilder<QuerySnapshot>(
                                        stream: firestore.collection('novels').doc(doc.id).collection('chapters').snapshots(),
                                        builder: (context, chapSnapshot) {
                                          int count = chapSnapshot.hasData ? chapSnapshot.data!.docs.length : 0;
                                          return Text("$count chương",
                                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey));
                                        },
                                      ),
                                      const SizedBox(width: 15),
                                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      // Tính điểm Ratings
                                      StreamBuilder<QuerySnapshot>(
                                        stream: firestore.collection('novels').doc(doc.id).collection('ratings').snapshots(),
                                        builder: (context, rateSnapshot) {
                                          double avg = 0.0;
                                          if (rateSnapshot.hasData && rateSnapshot.data!.docs.isNotEmpty) {
                                            double sum = 0;
                                            for (var rDoc in rateSnapshot.data!.docs) {
                                              final rData = rDoc.data() as Map<String, dynamic>;
                                              // Thử lấy từ các key phổ biến: rating, score, stars
                                              final val = rData['rating'] ?? rData['score'] ?? rData['stars'] ?? 0.0;
                                              sum += (val is int) ? val.toDouble() : val;
                                            }
                                            avg = sum / rateSnapshot.data!.docs.length;
                                          }
                                          return Text(avg.toStringAsFixed(1),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold));
                                        },
                                      ),
                                    ],
                                  ),
                                  // const Spacer(),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     _buildStatusBadge("Mới cập nhật"),
                                  //     Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 14),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCoverImage(String url) {
    if (url.isEmpty || !url.startsWith('http')) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.white, size: 30));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.white)),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange));
      },
    );
  }
}