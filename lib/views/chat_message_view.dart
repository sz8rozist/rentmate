import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/chat_message.dart';

import '../viewmodels/chat_message_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class ChatMessageView extends ConsumerStatefulWidget {
  final String tenantId;

  const ChatMessageView({super.key, required this.tenantId});

  @override
  ConsumerState<ChatMessageView> createState() => _ChatMessageViewState();
}

class _ChatMessageViewState extends ConsumerState<ChatMessageView> {
  final TextEditingController _controller = TextEditingController();
  final String landlordId = 'landlord1';

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      senderId: landlordId,
      receiverId: widget.tenantId,
      message: text,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).addMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider).where((msg) =>
    (msg.senderId == landlordId && msg.receiverId ==  widget.tenantId) ||
        (msg.senderId ==  widget.tenantId && msg.receiverId == landlordId)).toList();

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          // A háttér lefedi a státusz sávot is
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/header-image.png', fit: BoxFit.cover),
              Container(color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              ),
              // A tartalmat beljebb húzzuk, hogy ne lógjon be a status bar területére
              Padding(
                padding: EdgeInsets.fromLTRB(60, MediaQuery.of(context).padding.top, 16, 0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Chat with - ${widget.tenantId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == landlordId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,  // max 70% szélesség
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent.shade200 : Colors.lightBlueAccent.shade400,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                      ),
                      child: Text(message.message, style: TextStyle(color: Colors.white),),
                    ),
                  ),
                );
              },

            ),
          ),
          Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Írj üzenetet...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
