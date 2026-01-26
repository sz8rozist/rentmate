import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../rest_api_config.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final service = ChatService(
    socketUrl: 'http://$host:3000', // vagy szerver URL-ed
    flatId: 0, // ideiglenes, joinRoom majd külön
    apiService: apiService,
  );
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
    // Realtime üzenetek hallgatása
    _sub = chatService.messageStream.listen((message) {
      final exists = state.any((m) => m.id == message.id);
      if (!exists) {
        state = [...state, message]..sort(
              (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      } else {
        // Ha létezik, frissíthetjük a csatolmányokat vagy content-et
        state = state.map((m) => m.id == message.id ? message : m).toList();
      }
    });
  }

  /// Szobához csatlakozás + előzmények betöltése
  Future<void> joinRoom(int flatId) async {
    state = [];
    chatService.joinRoom(flatId);
    final messages = await chatService.fetchMessages(flatId);
    state = messages;
  }

  /// Szöveges üzenet küldése
  void sendMessage(int flatId, int senderId, String content) {
    chatService.sendMessage(
      flatId: flatId,
      senderId: senderId,
      content: content,
    );
  }

  /// Fájl csatolása egy meglévő üzenethez
  Future<void> sendAttachment(int messageId, String filePath) async {
    final updatedMessage = await chatService.uploadFiles(
      messageId: messageId,
      filePaths: [filePath],
    );

    // Frissítjük az állapotot a UI-hoz
    final exists = state.any((m) => m.id == updatedMessage.id);
    if (!exists) {
      state = [...state, updatedMessage]..sort(
            (a, b) => a.createdAt.compareTo(b.createdAt),
      );
    } else {
      state = state.map((m) => m.id == updatedMessage.id ? updatedMessage : m).toList();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
