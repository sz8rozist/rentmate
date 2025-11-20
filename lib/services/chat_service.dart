import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:graphql/client.dart';
import 'package:http/http.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../graphql_error.dart';
import '../models/message_model.dart';

class ChatService {
  final IO.Socket socket;
  final _messageController = StreamController<MessageModel>.broadcast();

  final GraphQLClient client;

  ChatService(String serverUrl, this.client)
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

  Future<int?> sendMessage({
    required int flatId,
    required int senderId,
    required String content,
  }) async {
    final completer = Completer<int?>();

    socket.emitWithAck(
      'sendMessage',
      {
        'flatId': flatId,
        'senderId': senderId,
        'content': content,
      },
      ack: (data) {
        // data a backend által visszaküldött message objektum id-ja
        completer.complete(data as int?);
      },
    );

    return completer.future;
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

  void sendAttachment({required int messageId, required String filePath}) {
    socket.emit('uploadAttachment', {
      'messageId': messageId,
      'file': filePath
    });
  }
}
