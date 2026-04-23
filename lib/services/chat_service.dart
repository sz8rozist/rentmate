import 'dart:async';
import 'package:dio/dio.dart';
import 'package:rentmate/models/message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../rest_api_config.dart';

class ChatService {
  final IO.Socket socket;
  final ApiService apiService;
  final StreamController<MessageModel> _messageController =
  StreamController<MessageModel>.broadcast();

  ChatService({
    required String socketUrl,
    required this.apiService,
  }) : socket = IO.io(
    socketUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  ) {
    _setupListeners();
    socket.connect();
  }

  /// Realtime listener
  void _setupListeners() {
    socket.on('receive_message', (data) {
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    });
  }

  Stream<MessageModel> get messageStream => _messageController.stream;

  /// Szobához csatlakozás
  void joinRoom(int flatId) {
    socket.emit('joinRoom', {'flatId': flatId});
  }

  /// Szöveges üzenet küldése Socket.IO-val
  void sendMessage({
    required int flatId,
    required int senderId,
    required String content,
  }) {
    socket.emit('send_message', {
      'flatId': flatId,
      'senderId': senderId,
      'content': content,
    });
  }

  /// Chat előzmények lekérése REST API-val
  Future<List<MessageModel>> fetchMessages(int flatId) async {
    final data = await apiService.get('/chat/messages/$flatId');
    final messages =
    (data as List).map((json) => MessageModel.fromJson(json)).toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  /// Fájlok feltöltése egy meglévő üzenethez REST API-val
  Future<MessageModel> uploadFiles({
    required int messageId,
    required List<String> filePaths,
  }) async {
    final formData = FormData();
    for (var path in filePaths) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(path, filename: path.split('/').last),
      ));
    }

    final data = await apiService.post(
      '/chat/messages/$messageId/files',
      formData as Map<String, dynamic>,
      authRequired: true,
    );

    return MessageModel.fromJson(data);
  }

  void dispose() {
    _messageController.close();
    socket.dispose();
  }
}
