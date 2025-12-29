class Novel {
  final int id;
  final String title;
  final String author;
  final String coverUrl;

  Novel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  factory Novel.fromJson(Map<String, dynamic> json) {
    return Novel(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['cover_url'],
    );
  }
}
