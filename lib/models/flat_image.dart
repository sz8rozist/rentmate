class FlatImage {
  final String? id;
  final String flatId;
  final String imageUrl;

  FlatImage({this.id, required this.flatId, required this.imageUrl});

  factory FlatImage.fromJson(Map<String, dynamic> json) {
    return FlatImage(
      id: json['id'] as String,
      flatId: json['flat_id'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flat_id': flatId,
      'image_url': imageUrl,
    };
  }
}
