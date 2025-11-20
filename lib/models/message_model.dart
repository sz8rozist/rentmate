import 'dart:convert';

import 'package:rentmate/models/user_model.dart';

class MessageModel {
  final int? id;
  final int flatId;
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
      id: int.tryParse(json['id'].toString()),
      flatId: int.parse(json['flatId'].toString()),
      senderUser: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrls'],
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
