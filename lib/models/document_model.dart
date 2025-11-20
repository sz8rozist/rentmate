class Document {
  final int? id;
  final String name;
  final String url;
  final String type;
  final String category;
  final String filePath;
  final String flatId;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.category,
    required this.filePath,
    required this.flatId,
    required this.uploadedAt,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: int.tryParse(map['id']),
      name: map['name'],
      url: map['url'],
      type: map['type'],
      category: map['category'],
      filePath: map['file_path'],
      flatId: map['flat_id'],
      uploadedAt: DateTime.parse(map['uploaded_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'url': url,
    'type': type,
    'category': category,
    'file_path': filePath,
    'flat_id': flatId,
    'uploaded_at': uploadedAt.toIso8601String(),
  };
}
