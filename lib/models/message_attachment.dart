class MessageAttachment {
  final int? id;
  final String url;

  MessageAttachment({
    required this.id,
    required this.url,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: int.tryParse(json['id'].toString()),
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}