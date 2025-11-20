import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';

class ChatService {
  final IO.Socket socket;
  final _messageController = StreamController<MessageModel>.broadcast();

  ChatService(String serverUrl)
      : socket = IO.io(
    serverUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  ) {
    _setupListeners();
    socket.connect();
  }

  void _setupListeners() {
    // Új üzenet érkezett
    socket.on('messageAdded', (data) {
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    });

    // Teljes chat történet lekérése
    socket.on('messages', (data) {
      if (data is List) {
        for (var msgJson in data) {
          final msg = MessageModel.fromJson(msgJson);
          _messageController.add(msg);
        }
      }
    });
  }

  Stream<MessageModel> get messageStream => _messageController.stream;

  // Szoba csatlakozás
  void joinRoom(int flatId) {
    socket.emit('joinRoom', {'flatId': flatId});
  }

  Future<void> sendMessage({
    required int flatId,
    required int senderId,
    required String content,
  }) async {
    socket.emit('sendMessage', {
      'flatId': flatId,
      'senderId': senderId,
      'content': content,
    });
  }

  /// Teljes chat történet lekérése
  Future<void> fetchInitialMessages(int flatId) async {
    final completer = Completer<void>();

    // Egyszeri listener a válaszra
    void handler(dynamic data) {
      if (data is List) {
        for (var msgJson in data) {
          final msg = MessageModel.fromJson(msgJson);
          _messageController.add(msg);
        }
      }
      completer.complete();
      socket.off('messages', handler);
    }

    socket.on('messages', handler);
    socket.emit('getMessages', {'flatId': flatId});

    return completer.future;
  }

  void dispose() {
    _messageController.close();
    socket.dispose();
  }
}
