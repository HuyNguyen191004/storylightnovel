import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/genre.dart';

class GenreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Lấy Stream danh sách thể loại từ Firebase (Cập nhật thời gian thực)
  Stream<List<Genre>> getGenresStream() {
    return firestore.collection('genres').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Genre.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  /// Lấy danh sách thể loại một lần từ Firebase
  Future<List<Genre>> getGenres() async {
    final snapshot = await firestore.collection('genres').get();
    return snapshot.docs
        .map((doc) => Genre.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  /// Thêm một thể loại mới (có kiểm tra trùng lặp)
  Future<Genre> addGenre(String name) async {
    // Kiểm tra xem thể loại với tên này đã tồn tại trong Firestore chưa
    final query = await firestore
        .collection('genres')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Genre.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    }

    // Nếu chưa tồn tại thì mới thêm mới
    final docRef = await firestore.collection('genres').add({'name': name});
    final doc = await docRef.get();
    return Genre.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }
}
