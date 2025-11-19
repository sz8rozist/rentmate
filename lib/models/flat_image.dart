class FlatImage {
  final int? id;
  final int? flatId;
  final String filename;
  final String url;

  FlatImage({this.id, this.flatId, required this.url, required this.filename});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flatId': flatId,
      'filename': filename,
      'url': url,
    };
  }

  factory FlatImage.fromJson(Map<String, dynamic> json) {
    return FlatImage(
      id: int.tryParse(json['id']),
      flatId: int.tryParse(json['flatId'].toString()),
      filename: json['filename'] as String,
      url: json['url'] as String,
    );
  }
}
