import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReadingView extends StatefulWidget {
  final List<Map<String, String>> chapters;
  final int initialIndex;
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
  late PageController _pageController;
  List<String> _pages = [];
  int _currentPageInView = 0;

  // --- CẤU HÌNH GIAO DIỆN ---
  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFFF5F5DC);
  Color _textColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController();
    _updateHistory();
    // Chờ frame đầu tiên để lấy kích thước màn hình chính xác
    WidgetsBinding.instance.addPostFrameCallback((_) => _paginateContent());
  }

  // Thuật toán chia trang (Phải gọi lại khi đổi cỡ chữ)
  void _paginateContent({bool goToLastPage = false}) {
    if (!mounted) return;

    final String content = widget.chapters[currentIndex]['content']?.replaceAll(r'\n', '\n') ?? "";

    // Tính toán kích thước vùng chứa văn bản thực tế
    // Trừ đi AppBar (kToolbarHeight) và thanh điều hướng phía dưới (~60)
    final double width = MediaQuery.of(context).size.width - 40;
    final double height = MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 80;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: content,
        style: TextStyle(fontSize: _fontSize, height: 1.8, fontFamily: 'Roboto'),
      ),
    );

    textPainter.layout(maxWidth: width);

    List<String> pages = [];
    int start = 0;
    while (start < content.length) {
      int end = textPainter.getPositionForOffset(Offset(width, height)).offset;
      if (end <= start) {
        pages.add(content.substring(start));
        break;
      }
      pages.add(content.substring(start, end));
      start = end;
      textPainter.text = TextSpan(
        text: content.substring(start),
        style: TextStyle(fontSize: _fontSize, height: 1.8, fontFamily: 'Roboto'),
      );
      textPainter.layout(maxWidth: width);
    }

    setState(() {
      _pages = pages;
      _currentPageInView = goToLastPage ? _pages.length - 1 : 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentPageInView);
    }
  }

  void _showAppearanceSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 250,
              child: Column(
                children: [
                  const Text("Cài đặt giao diện", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("Cỡ chữ"),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.remove), onPressed: () {
                        setState(() => _fontSize--);
                        setModalState(() {});
                        _paginateContent();
                      }),
                      Text(_fontSize.toInt().toString()),
                      IconButton(icon: const Icon(Icons.add), onPressed: () {
                        setState(() => _fontSize++);
                        setModalState(() {});
                        _paginateContent();
                      }),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Màu nền"),
                      const Spacer(),
                      _colorCircle(Colors.white, Colors.black),
                      _colorCircle(const Color(0xFFF5F5DC), Colors.black87),
                      _colorCircle(const Color(0xFF2C2C2C), Colors.white70),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _colorCircle(Color bg, Color text) {
    return GestureDetector(
      onTap: () => setState(() { _backgroundColor = bg; _textColor = text; }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _backgroundColor == bg ? Colors.orange : Colors.grey, width: 2),
        ),
        child: CircleAvatar(backgroundColor: bg, radius: 15),
      ),
    );
  }

  void _handleBack() {
    if (_currentPageInView > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (currentIndex > 0) {
      setState(() => currentIndex--);
      _paginateContent(goToLastPage: true);
      _updateHistory();
    }
  }

  void _handleNext() {
    if (_currentPageInView < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (currentIndex < widget.chapters.length - 1) {
      setState(() => currentIndex++);
      _paginateContent();
      _updateHistory();
    }
  }

  Future<void> _updateHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('history').doc(widget.novelId).set({
        'novelId': widget.novelId,
        'title': widget.novelTitle,
        'coverUrl': widget.coverUrl,
        'lastChapterIndex': currentIndex,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { debugPrint(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chapters[currentIndex]['title'] ?? "Chương ${currentIndex + 1}";

    return Scaffold(
      backgroundColor: _backgroundColor,
      // AppBar dính cứng mặc định của Scaffold
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0.5, // Thêm đổ bóng nhẹ để phân biệt với nội dung
        iconTheme: IconThemeData(color: _textColor.withOpacity(0.7)),
        title: Text(title, style: TextStyle(fontSize: 16, color: _textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showAppearanceSettings),
        ],
      ),
      // Sử dụng SafeArea để bảo vệ nội dung không bị tai thỏ hay thanh điều hướng hệ thống che
      body: SafeArea(
        child: _pages.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPageInView = i),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    // Đảm bảo văn bản không bao giờ tràn qua giới hạn
                    child: Text(
                      _pages[index],
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: _textColor,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  );
                },
              ),
            ),
            // Thanh điều hướng cố định phía dưới
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border(top: BorderSide(color: _textColor.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: (currentIndex == 0 && _currentPageInView == 0) ? null : _handleBack,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: Text(_currentPageInView == 0 ? "Chương trước" : "Trang trước"),
                  ),
                  Text(
                    "${_currentPageInView + 1} / ${_pages.length}",
                    style: TextStyle(color: _textColor.withOpacity(0.5), fontSize: 13),
                  ),
                  TextButton(
                    onPressed: (currentIndex == widget.chapters.length - 1 && _currentPageInView == _pages.length - 1) ? null : _handleNext,
                    child: Row(
                      children: [
                        Text(_currentPageInView == _pages.length - 1 ? "Chương sau" : "Trang sau"),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}