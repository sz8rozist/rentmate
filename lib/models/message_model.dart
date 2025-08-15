import 'dart:convert';

import 'package:rentmate/models/user_model.dart';

class MessageModel {
  final String id;
  final String flatId;
  final UserModel senderUser;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.flatId,
    required this.senderUser,
    required this.content,
    required this.createdAt,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      flatId: json['flat_id'],
      senderUser: UserModel.fromJson(json['sender_user']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_urls'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flat_id': flatId,
      'sender_user': senderUser.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'image_urls': jsonEncode(imageUrls),
    };
  }

  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(imageUrl!);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}
