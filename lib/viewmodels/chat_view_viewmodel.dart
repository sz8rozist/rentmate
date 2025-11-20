import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

// ChatService provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService('http://localhost:3000');
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

  void sendMessage(int flatId, int senderId, String content) {
    chatService.sendMessage(
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
}
