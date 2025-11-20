import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/GraphQLConfig.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

// ChatService provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  final service = ChatService('http://$host:3000', client.value);
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
      state = [...state, message]; // új üzenet hozzáadása
    });
  }

  void joinRoom(int flatId) {
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
