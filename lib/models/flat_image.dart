class FlatImage {
  final int? id;
  final int? flatId;
  final String filename;
  final String? url;

  FlatImage({this.id, this.flatId, this.url, required this.filename});

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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()),
      flatId: json['flatId'] is int ? json['flatId'] as int : int.tryParse(json['flatId']?.toString() ?? ''),
      filename: json['filename'] as String,
      url: json['url'] as String?,
    );
  }

}
