import 'dart:convert';

import 'package:rentmate/models/user_model.dart';

class MessageModel {
  final int? id;
  final int flatId;
  final UserModel senderUser;
  final String content;
  final DateTime createdAt;
  final List<String> imageUrls;

  MessageModel({
    required this.id,
    required this.flatId,
    required this.senderUser,
    required this.content,
    required this.createdAt,
    required this.imageUrls,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Ha a backend null-t küld, vagy üres stringet, mindig üres listára alakítjuk
    List<String> images = [];
    if (json['imageUrls'] != null) {
      try {
        if (json['imageUrls'] is String) {
          // Ha JSON string jön
          images = List<String>.from(jsonDecode(json['imageUrls']));
        } else if (json['imageUrls'] is List) {
          // Ha már lista jön
          images = List<String>.from(json['imageUrls']);
        }
      } catch (e) {
        images = [];
      }
    }
    return MessageModel(
      id: int.tryParse(json['id'].toString()),
      flatId: int.parse(json['flatId'].toString()),
      senderUser: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrls: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flatId': flatId,
      'senderUser': senderUser.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': jsonEncode(imageUrls),
    };
  }

}
