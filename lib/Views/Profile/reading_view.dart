import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReadingView extends StatefulWidget {
  final List<Map<String, String>> chapters;
  final int initialIndex;
  // Bổ sung các thông tin cần thiết để lưu lịch sử
  final String novelId;
  final String novelTitle;
  final String coverUrl;

  const ReadingView({
    super.key,
    required this.chapters,
    required this.novelId,
    required this.novelTitle,
    required this.coverUrl,
    this.initialIndex = 0,
  });

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  late int currentIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    // Lưu lịch sử ngay lần đầu tiên mở truyện
    _updateHistory();
  }

  // Hàm cập nhật lịch sử đọc truyện
  Future<void> _updateHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(widget.novelId)
          .set({
        'novelId': widget.novelId,
        'title': widget.novelTitle,
        'coverUrl': widget.coverUrl,
        'lastChapterIndex': currentIndex,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Lỗi lưu lịch sử: $e");
    }
  }

  void goToNextChapter() {
    if (currentIndex < widget.chapters.length - 1) {
      setState(() {
        currentIndex++;
      });
      _scrollToTop();
      _updateHistory(); // Cập nhật tiến trình khi sang chương mới
    }
  }

  void goToPreviousChapter() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _scrollToTop();
      _updateHistory(); // Cập nhật tiến trình khi quay lại chương trước
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra danh sách chương tránh lỗi index out of bounds
    if (widget.chapters.isEmpty) {
      return const Scaffold(body: Center(child: Text("Không có nội dung chương")));
    }

    final currentChapter = widget.chapters[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentChapter['title'] ?? "Chương ${currentIndex + 1}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Text(
          currentChapter['content']?.replaceAll(r'\n', '\n') ?? "",
          style: const TextStyle(
            fontSize: 18,
            height: 1.6,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: currentIndex > 0 ? goToPreviousChapter : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Trước"),
            ),
            Text("${currentIndex + 1} / ${widget.chapters.length}"),
            TextButton.icon(
              onPressed: currentIndex < widget.chapters.length - 1
                  ? goToNextChapter
                  : null,
              label: const Text("Sau"),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}