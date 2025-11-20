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
  }

  Stream<MessageModel> get messageStream => _messageController.stream;

  // Szoba csatlakozás
  void joinRoom(int flatId) {
    socket.emit('joinRoom', {'flatId': flatId});
  }

  // Üzenet küldés
  void sendMessage({
    required int flatId,
    required int senderId,
    required String content,
  }) {
    socket.emit('sendMessage', {
      'flatId': flatId,
      'senderId': senderId,
      'content': content,
    });
  }

  // Lekérhetjük a chat történetet a backendről (opcionális)
  Future<List<MessageModel>> fetchInitialMessages(int flatId) async {
    // Ezt maradhat GraphQL-lel, vagy csinálhatsz REST endpointot
    return [];
  }

  void dispose() {
    _messageController.close();
    socket.dispose();
  }
}
