import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../GraphQLConfig.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, List<MessageModel>, int>((
      ref,
      flatId,
    ) {
      final service = ref.watch(chatServiceProvider);
      return ChatViewModel(service, flatId);
    });
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  return ChatService(client.value);
});

class ChatViewModel extends StateNotifier<List<MessageModel>> {
  final ChatService _service;
  final int flatId;
  StreamSubscription<MessageModel>? _subscription;

  ChatViewModel(this._service, this.flatId) : super([]) {
    _init();
  }

  Future<void> _init() async {
    //Betöltjük a teljes listát
    final initialMessages = await _service.fetchInitialMessages(flatId);
    state = initialMessages;

    //Elindítjuk a Subscription-t a valós idejű üzenetekhez
    _subscription = _service.subscribeToMessages(flatId).listen((newMessage) {
      state = [...state, newMessage]; // hozzáadjuk az új üzenetet
    });
  }

  //Üzenet küldés
  Future<void> sendMessage(
    int senderUserId,
    String content,
    List<File>? files,
  ) async {
    await _service.sendMessage(flatId, senderUserId, content, files);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
