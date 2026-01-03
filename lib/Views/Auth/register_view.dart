// File: lib/Views/register_view.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- GIỮ NGUYÊN CHỨC NĂNG ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'email': user.email,
          'created_at': FieldValue.serverTimestamp(),
        });
        await user.sendEmailVerification();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng xác nhận email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError('Đăng ký thất bại: ${e.message}');
    } catch (e) {
      _showError('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- GIAO DIỆN ĐỒNG BỘ ---
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
                  "Đăng ký",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // // Hình ảnh trung tâm đồng bộ
                // Container(
                //   width: 130,
                //   height: 130,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFF0F0F0),
                //     shape: BoxShape.circle,
                //     image: const DecorationImage(
                //       image: AssetImage('Assets/Images/Icon.png'),
                //       fit: BoxFit.cover,
                //     ),
                //     border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                //   ),
                // ),
                // const SizedBox(height: 40),

                // Tên người dùng
                TextFormField(
                  controller: _usernameController,
                  decoration: _buildInputDecoration('Tên người dùng'),
                  validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 15),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email'),
                  validator: (val) => val != null && val.contains('@') ? null : 'Email không hợp lệ',
                ),
                const SizedBox(height: 15),

                // Mật khẩu
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildInputDecoration('Mật khẩu'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (val.length < 6) return 'Ít nhất 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Nút Đăng ký màu Cam
                _loading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _register,
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Link chuyển về Đăng nhập màu Cam
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Đã có tài khoản? ',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng nhập ngay',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
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

  // Helper để tạo kiểu cho các ô nhập liệu giống nhau
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5), // Màu xám nhạt đồng bộ
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}