class Document {
  final String id;
  final String name;
  final String url;
  final String category;
  final String flatId;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.flatId,
    required this.uploadedAt,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      category: map['category'],
      flatId: map['flatId'],
      uploadedAt: DateTime.parse(map['uploaded_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'url': url,
    'category': category,
    'flatId': flatId,
    'uploaded_at': uploadedAt.toIso8601String(),
  };
}
