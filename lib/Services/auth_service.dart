import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  /// Đăng ký tài khoản mới với email, password và username
  Future<bool> register(String email, String password, String username) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username, // lưu username vào user_metadata
      },
    );

    if (response.user != null) {
      print("Đăng ký thành công: ${response.user!.email}, username: $username");
      return true;
    } else {
      print("Đăng ký thất bại");
      return false;
    }
  }

  /// Đăng nhập với email và password
  Future<bool> login(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session != null) {
      print("Đăng nhập thành công, user: ${response.user?.email}");
      return true;
    } else {
      print("Đăng nhập thất bại");
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await supabase.auth.signOut();
    print("Đã đăng xuất");
  }
}