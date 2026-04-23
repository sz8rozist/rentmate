import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../rest_api_config.dart';
import '../services/chat_service.dart';

// ---------------------------------------------------------------------------
// Service Provider
// ---------------------------------------------------------------------------

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService(
    socketUrl: 'http://$host:3000',
    apiService: ref.watch(apiServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.currentRoomId,
  });

  final List<MessageModel> messages;
  final bool isLoading;
  final int? currentRoomId;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    int? currentRoomId,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        currentRoomId: currentRoomId ?? this.currentRoomId,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class ChatNotifier extends Notifier<ChatState> {
  ChatService get _service => ref.read(chatServiceProvider);
  StreamSubscription<MessageModel>? _sub;

  @override
  ChatState build() {
    // Provider dispose-kor automatikusan lefut
    ref.onDispose(() => _sub?.cancel());

    _sub = _service.messageStream.listen(_onMessageReceived);

    return const ChatState();
  }

  // --- Stream handler ---

  void _onMessageReceived(MessageModel message) {
    state = state.copyWith(messages: _upsert(state.messages, message));
  }

  // --- Public API ---

  /// Szobához csatlakozás + előzmények betöltése
  Future<void> joinRoom(int flatId) async {
    // Ha már ebben a szobában vagyunk, skip
    if (state.currentRoomId == flatId) return;

    state = state.copyWith(
      messages: [],
      isLoading: true,
      currentRoomId: flatId,
    );

    try {
      _service.joinRoom(flatId);
      final history = await _service.fetchMessages(flatId);
      state = state.copyWith(messages: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Szöveges üzenet küldése
  void sendMessage({
    required int flatId,
    required int senderId,
    required String content,
  }) {
    _service.sendMessage(
      flatId: flatId,
      senderId: senderId,
      content: content,
    );
  }

  /// Fájl csatolása egy üzenethez
  Future<void> sendAttachment({
    required int messageId,
    required String filePath,
  }) async {
    final updated = await _service.uploadFiles(
      messageId: messageId,
      filePaths: [filePath],
    );
    state = state.copyWith(messages: _upsert(state.messages, updated));
  }

  // --- Helper ---

  /// Beszúr vagy frissít egy üzenetet, majd id szerint rendezi
  List<MessageModel> _upsert(List<MessageModel> current, MessageModel msg) {
    final exists = current.any((m) => m.id == msg.id);
    final updated = exists
        ? current.map((m) => m.id == msg.id ? msg : m).toList()
        : [...current, msg];
    return updated..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> sendMessageWithAttachments({
    required int flatId,
    required int senderId,
    required String content,
    required List<File> attachments,
  }) async {
    _service.sendMessage(flatId: flatId, senderId: senderId, content: content);

    if (attachments.isEmpty) return;

    // Várjuk meg a saját üzenetet a streamből
    final sent = await _service.messageStream.firstWhere(
          (msg) => msg.senderUser.id == senderId && msg.content == content,
    );

    for (final file in attachments) {
      await sendAttachment(messageId: sent.id as int, filePath: file.path);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);