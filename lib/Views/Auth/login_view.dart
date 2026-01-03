import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storylightnovel/Views/main_screen.dart';
import '../Auth/register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // --- GIỮ NGUYÊN CHỨC NĂNG QUÊN MẬT KHẨU ---
  Future<void> _forgotPassword() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quên mật khẩu?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập email của bạn để nhận liên kết đặt lại mật khẩu."),
            const SizedBox(height: 15),
            TextField(
              controller: _resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final email = _resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                _showError("Vui lòng nhập email hợp lệ");
                return;
              }
              try {
                await _auth.sendPasswordResetEmail(email: email);
                Navigator.pop(context);
                _resetEmailController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Liên kết đã được gửi!"), backgroundColor: Colors.green),
                );
              } catch (e) {
                _showError("Lỗi hệ thống.");
              }
            },
            child: const Text("Gửi mã"),
          ),
        ],
      ),
    );
  }

  // --- GIỮ NGUYÊN CHỨC NĂNG ĐĂNG NHẬP ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        } else {
          _showError("Email chưa xác nhận. Vui lòng kiểm tra hộp thư.");
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError("Sai email hoặc mật khẩu");
    } catch (e) {
      _showError("Có lỗi xảy ra: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Đăng nhập",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 30),

                // // Vòng tròn đã ADD HÌNH (Sử dụng NetworkImage hoặc AssetImage)
                // Container(
                //   width: 130,
                //   height: 130,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFD9D9D9),
                //     shape: BoxShape.circle,
                //     image: const DecorationImage(
                //       image: AssetImage('Assets/Images/Icon.png'),
                //       fit: BoxFit.cover,
                //     ),
                //     border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                //   ),
                // ),
                // const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val != null && val.contains('@') ? null : 'Email không hợp lệ',
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  validator: _validatePassword,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // NÚT ĐĂNG NHẬP MÀU CAM
                _loading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Đổi sang màu cam
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dòng Đăng ký đổi sang màu cam
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng ký ngay',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
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
  }
}