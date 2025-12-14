import 'dart:async';

import 'package:graphql/client.dart';
import 'package:rentmate/services/file_upload_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';

class ChatService {
  final IO.Socket socket;
  final _messageController = StreamController<MessageModel>.broadcast();
  final FileUploadService fileUploadService;
  final GraphQLClient client;

  ChatService(String serverUrl, this.fileUploadService, this.client)
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
        final messages = data
            .map((msgJson) => MessageModel.fromJson(msgJson))
            .toList();

        // sort createdAt szerint
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        for (var msg in messages) {
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

  /*void sendAttachment({required int messageId, required String filePath}) {
    socket.emit('uploadAttachment', {
      'messageId': messageId,
      'file': filePath
    });
  }*/

  Future<bool> sendAttachment({
    required int messageId,
    required String filePath,
  }) async {
    const mutation = r'''
      mutation UploadAttachment($messageId: Int!, $file: Upload!) {
        uploadAttachment(messageId: $messageId, file: $file)
      }
    ''';

    final variables = {
        "messageId": messageId,
    };

    final success = await fileUploadService.uploadSingleFile(
      mutation: mutation,
      variables: variables,
      filePath: filePath,
      fileVariableName: 'file',
    );

    return success;
  }
}
