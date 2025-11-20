import 'dart:convert';

import 'package:rentmate/models/message_attachment.dart';
import 'package:rentmate/models/user_model.dart';

class MessageModel {
  final int? id;
  final int flatId;
  final UserModel senderUser;
  final String content;
  final DateTime createdAt;
  final List<MessageAttachment>? messageAttachments;

  MessageModel({
    required this.id,
    required this.flatId,
    required this.senderUser,
    required this.content,
    required this.createdAt,
    required this.messageAttachments,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: int.tryParse(json['id'].toString()),
      flatId: int.parse(json['flatId'].toString()),
      senderUser: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      messageAttachments:(json['messageAttachments'] as List<dynamic>?)
          ?.map((e) => MessageAttachment.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flatId': flatId,
      'senderUser': senderUser.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': messageAttachments,
    };
  }

}
