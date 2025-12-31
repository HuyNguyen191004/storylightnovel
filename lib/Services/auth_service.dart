import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Đăng ký tài khoản mới với email và password
  Future<bool> register(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật thêm displayName (username)
      await userCredential.user?.updateDisplayName(username);

      print("Đăng ký thành công: ${userCredential.user?.email}, username: $username");
      print("Firebase sẽ tự động gửi email xác nhận nếu bạn bật Email Verification.");

      // Gửi email xác nhận
      await userCredential.user?.sendEmailVerification();

      return true;
    } catch (e) {
      print("Đăng ký thất bại: $e");
      return false;
    }
  }

  /// Đăng nhập với email và password
  Future<bool> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null && user.emailVerified) {
        print("Đăng nhập thành công, email đã xác nhận: ${user.email}");
        return true;
      } else {
        print("Email chưa xác nhận: ${user?.email}");
        return false;
      }
    } catch (e) {
      print("Đăng nhập thất bại: $e");
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    print("Đã đăng xuất");
  }
}