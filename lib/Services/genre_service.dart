import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/genre.dart';

class GenreService {
  final supabase = Supabase.instance.client;

  /// Lấy danh sách thể loại từ Supabase
  Future<List<Genre>> getGenres() async {
    final response = await supabase.from('genres').select();
    return (response as List)
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Thêm một thể loại mới
  Future<Genre> addGenre(String name) async {
    final response = await supabase
        .from('genres')
        .insert({'name': name})
        .select()
        .single();
    return Genre.fromJson(response as Map<String, dynamic>);
  }
}