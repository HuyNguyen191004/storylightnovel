import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/genre.dart';

class GenreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Lấy danh sách thể loại từ Firebase
  Future<List<Genre>> getGenres() async {
    final snapshot = await firestore.collection('genres').get();
    return snapshot.docs
        .map((doc) => Genre.fromJson({
      'id': doc.id,
      ...doc.data(),
    }))
        .toList();
  }

  /// Thêm một thể loại mới
  Future<Genre> addGenre(String name) async {
    final docRef = await firestore.collection('genres').add({'name': name});
    final doc = await docRef.get();
    return Genre.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }
}