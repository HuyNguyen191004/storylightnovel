import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storylightnovel/Views/main_screen.dart';
import '../Auth/register_view.dart';
import '../Home/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); // Controller cho email khôi phục

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ QUÊN MẬT KHẨU ---
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
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
                  const SnackBar(
                    content: Text("Liên kết đặt lại mật khẩu đã được gửi! Kiểm tra email của bạn."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showError("Lỗi: Không tìm thấy người dùng hoặc lỗi hệ thống.");
              }
            },
            child: const Text("Gửi mã"),
          ),
        ],
      ),
    );
  }

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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.contains('@') ? null : 'Email không hợp lệ',
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                validator: _validatePassword,
              ),

              // NÚT QUÊN MẬT KHẨU
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.orange)),
                ),
              ),

              const SizedBox(height: 10),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterView()),
                  );
                },
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}