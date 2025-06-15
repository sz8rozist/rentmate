class FlatImage {
  final String? id;
  final String flatId;
  final String imageUrl;
  final String imagePath;

  FlatImage({this.id, required this.flatId, required this.imageUrl, required this.imagePath});

  factory FlatImage.fromJson(Map<String, dynamic> json) {
    return FlatImage(
      id: json['id'] as String,
      flatId: json['flat_id'] as String,
      imageUrl: json['image_url'] as String,
      imagePath: json['image_path'] as String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flat_id': flatId,
      'image_url': imageUrl,
      'image_path': imagePath
    };
  }
}
