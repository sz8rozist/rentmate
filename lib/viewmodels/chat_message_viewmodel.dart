import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      (ref) => ChatMessagesNotifier(),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super(_dummyData());

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  // Dummy adatok
  static List<ChatMessage> _dummyData() {
    return [
      ChatMessage(
        id: 'msg1',
        senderId: 'landlord1',
        receiverId: 'tenant1',
        message: 'Szia, érdeklődöm, mikor tudunk találkozni a lakás miatt?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: 'msg2',
        senderId: 'tenant1',
        receiverId: 'landlord1',
        message: 'Holnap délután jó lenne?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'msg3',
        senderId: 'landlord1',
        receiverId: 'tenant1',
        message: 'Rendben, akkor várlak 3-kor!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}
