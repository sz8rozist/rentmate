import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/services/chat_service.dart';

import '../models/flat_model.dart';
import '../models/message_model.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final flatsProvider = FutureProvider.family<List<Flat>, UserModel>((
  ref,
  loggedInUser,
) {
  final service = ref.watch(chatServiceProvider);
  return service.getFlatsForCurrentUser(loggedInUser);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, int>((
  ref,
  flatId,
) {
  final service = ref.watch(chatServiceProvider);
  return service.subscribeToMessages(flatId);
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  final service = ref.watch(chatServiceProvider);
  return (int flatId, int senderUserId, String content, List<File>? file) {
    return service.sendMessage(flatId, senderUserId, content, file);
  };
});

// Egy típusdefiníció a könnyebb használathoz
typedef SendMessage = Future<void> Function(int flatId, int senderUserId, String content, List<File>? file);
