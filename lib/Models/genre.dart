class Genre {
  final String id;
  final String name;

  Genre({required this.id, required this.name});

  // THÊM ĐOẠN NÀY: Hàm khởi tạo từ Map (Json)
  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  // Nên thêm cái này để Dropdown hoạt động chính xác
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Genre && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}