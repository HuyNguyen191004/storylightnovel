import 'package:cloud_firestore/cloud_firestore.dart';

class Novel {
  final String id; // ID của document trên Firestore
  final String title;
  final String author;
  final String coverUrl;
  final String description;
  final List<String> genres; // Danh sách thể loại

  Novel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.description = '',
    this.genres = const [],
  });

  // Chỉnh sửa factory để lấy dữ liệu từ Firestore một cách an toàn
  factory Novel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Xử lý genres: Ép kiểu từ dynamic sang List<String>
    var rawGenres = data['genres'];
    List<String> parsedGenres = [];
    if (rawGenres is List) {
      parsedGenres = List<String>.from(rawGenres);
    } else if (rawGenres is String && rawGenres.isNotEmpty) {
      parsedGenres = [rawGenres];
    }

    return Novel(
      id: doc.id,
      title: data['title'] ?? 'Không tiêu đề',
      author: data['author'] ?? 'Ẩn danh',
      coverUrl: data['cover_url'] ?? '',
      description: data['description'] ?? '',
      genres: parsedGenres,
    );
  }
}