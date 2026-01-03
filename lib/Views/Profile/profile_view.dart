import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Auth/login_view.dart';

import 'addnovel_view.dart';
import 'listnovel_view.dart';
import 'user_information_view.dart';
import 'history_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String adminEmail = "huytempest2@gmail.com";

  String get _displayIdentity {
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user?.email ?? "Người dùng";
  }

  String? get _avatarUrl => _auth.currentUser?.photoURL;

  // --- HÀM XỬ LÝ ĐĂNG TRUYỆN ---
  Future<void> _handlePostNovel() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      String role = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['role'] ?? "reader" : "reader";

      if (role == "author" || role == "admin" || user.email == adminEmail) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNovelView()));
      } else {
        _showRequestDialog();
      }
    } catch (e) {
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    }
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Chưa có quyền tác giả"),
        content: const Text("Gửi yêu cầu đến Admin để được cấp quyền đăng truyện?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () { Navigator.pop(context); _sendRequestToAdmin(); },
            child: const Text("Gửi yêu cầu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequestToAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('requests').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': _displayIdentity,
        'requestDate': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi yêu cầu!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showAdminManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text("Yêu cầu chờ duyệt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('requests').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("Không có yêu cầu nào."));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['displayName'] ?? "Ẩn danh"),
                          subtitle: Text(data['email'] ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _firestore.collection('requests').doc(docs[index].id).delete()),
                              IconButton(icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    _firestore.collection('users').doc(docs[index].id).update({'role': 'author'});
                                    _firestore.collection('requests').doc(docs[index].id).delete();
                                  }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                if (data['email'] == adminEmail) return const SizedBox.shrink();
                return ListTile(
                  title: Text(data['displayName'] ?? "Người dùng"),
                  subtitle: Text("${data['email']} - ${data['role'] == 'author' ? 'Tác giả' : 'Độc giả'}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'demote') _firestore.collection('users').doc(docs[index].id).update({'role': 'reader'});
                      if (val == 'delete') _firestore.collection('users').doc(docs[index].id).delete();
                    },
                    itemBuilder: (context) => [
                      if (data['role'] == 'author') const PopupMenuItem(value: 'demote', child: Text("Gỡ quyền Tác giả")),
                      const PopupMenuItem(value: 'delete', child: Text("Xóa tài khoản", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Lỗi xác thực")));

    bool isAdmin = currentUser.email == adminEmail;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Trang cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          String roleValue = "reader";
          String roleDisplay = "Độc giả";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            roleValue = data?['role'] ?? "reader";
            if (isAdmin) roleDisplay = "Admin";
            else if (roleValue == 'author') roleDisplay = "Tác giả";
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange,
                    backgroundImage: (_avatarUrl != null) ? NetworkImage(_avatarUrl!) : null,
                    child: (_avatarUrl == null) ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(_displayIdentity, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Chip(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      label: Text(roleDisplay, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(height: 20),

                  // --- PHẦN NÀY CHỈ DÀNH CHO ADMIN ---
                  if (isAdmin) ...[
                    _buildButton('Duyệt quyền Tác giả', Icons.admin_panel_settings, _showAdminManagement, textColor: Colors.blue),
                    _buildButton('Quản lý người dùng', Icons.people_alt, _showUserManagement, textColor: Colors.indigo),
                  ],

                  // --- PHẦN CHUNG (CẢ ADMIN VÀ USER ĐỀU THẤY) ---
                  _buildButton('Thông tin cá nhân', Icons.info_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInformationView()));
                  }),

                  // --- PHẦN NÀY CHỈ DÀNH CHO USER (ĐỘC GIẢ/TÁC GIẢ), ADMIN KHÔNG THẤY ---
                  if (!isAdmin) ...[
                    _buildButton('Lịch sử đã đọc', Icons.history, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryView()));
                    }),

                    if (roleValue != 'author')
                      _buildButton('Gửi yêu cầu Đăng truyện', Icons.add_circle_outline, _handlePostNovel),

                    if (roleValue == 'author') ...[
                      _buildButton('Đăng truyện mới', Icons.edit_note, _handlePostNovel, textColor: Colors.green),
                      _buildButton('Danh sách truyện đã đăng', Icons.list_alt, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ListNovelView()));
                      }),
                    ],
                  ],

                  const SizedBox(height: 20),
                  _buildButton('Đăng xuất', Icons.logout, _logout, textColor: Colors.red),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed, {Color? textColor}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor ?? Colors.black87, size: 22),
        label: Text(text, style: TextStyle(fontSize: 15, color: textColor ?? Colors.black87)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}