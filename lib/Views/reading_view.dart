import 'package:flutter/material.dart';

class ReadingView extends StatelessWidget {
  final String title;
  final String content;

  const ReadingView({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          // Xử lý xuống dòng cho nội dung
          content.replaceAll(r'\n', '\n'),
          style: const TextStyle(
            fontSize: 18,
            height: 1.6, // Khoảng cách dòng cho dễ đọc
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}