import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/GraphQLConfig.dart';
import 'package:rentmate/services/file_upload_service.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

// ChatService provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  final fileUploadService = FileUploadService(ref);
  final service = ChatService('http://$host:3000',fileUploadService, client.value);
  ref.onDispose(() => service.dispose());
  return service;
});

// Messages stream provider
final messagesProvider =
    StateNotifierProvider<ChatNotifier, List<MessageModel>>((ref) {
      final chatService = ref.watch(chatServiceProvider);
      return ChatNotifier(chatService);
    });

// ChatNotifier
class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final ChatService chatService;
  late final StreamSubscription<MessageModel> _sub;

  ChatNotifier(this.chatService) : super([]) {
    _sub = chatService.messageStream.listen((message) {
      final exists = state.any((m) => m.id == message.id);
      if (!exists) {
        state = [...state, message]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        // ha létezik, frissíthetjük a csatolmányokat vagy content-et
        state = state.map((m) => m.id == message.id ? message : m).toList();
      }
    });
  }

  void joinRoom(int flatId) {
    state = [];
    chatService.joinRoom(flatId);
    chatService.fetchInitialMessages(flatId);
  }

  Future<int?> sendMessage(int flatId, int senderId, String content) {
    return chatService.sendMessage(
      flatId: flatId,
      senderId: senderId,
      content: content,
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void sendAttachment(int messageId, String filePath) {
    chatService.sendAttachment(
      messageId: messageId,
      filePath: filePath,
    );
  }
}
