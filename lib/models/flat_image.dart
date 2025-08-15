class FlatImage {
  final int? id;
  final int? flatId;
  final String url;

  FlatImage({this.id, this.flatId, required this.url});

  factory FlatImage.fromJson(Map<String, dynamic> json) {
    return FlatImage(
      id: json['id'],
      flatId: json['flat_id'],
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flat_id': flatId,
      'url': url,
    };
  }
}
