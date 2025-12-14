import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/message_attachment.dart';
import '../models/message_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_view_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/message_attachment.dart';
import '../widgets/swipe_image_galery.dart';

class ChatMessageView extends ConsumerStatefulWidget {
  final int flatId;

  const ChatMessageView({super.key, required this.flatId});

  @override
  ConsumerState<ChatMessageView> createState() => _ChatMessageViewState();
}

class _ChatMessageViewState extends ConsumerState<ChatMessageView> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final List<File> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    // Szoba csatlakozás a notifier-en keresztül
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider.notifier).joinRoom(widget.flatId);
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageFiles.isEmpty) return;

    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;

    if (payload == null) {
      CustomSnackBar.error(context, 'Hiba: felhasználó azonosító nem elérhető');
      return;
    }

    final userId = payload.userId;
    final notifier = ref.read(messagesProvider.notifier);
    // Üzenet küldése a ChatNotifier-en keresztül
    final messageId = await notifier.sendMessage(widget.flatId, userId, text);
    if (messageId != null) {
      for (final file in _imageFiles) {
        notifier.sendAttachment(messageId, file.path);
      }
    }

    _controller.clear();
    _imageFiles.clear();
    FocusScope.of(context).unfocus();
    _scrollToEnd();
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildSelectedImagesPreview() {
    if (_imageFiles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _imageFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _imageFiles[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imageFiles.removeAt(index);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);

    ref.listen<List<MessageModel>>(messagesProvider, (previous, next) {
      if (previous?.length != next.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToEnd();
        });
      } else {
        // frissült egy meglévő üzenet (pl. új csatolmány), scroll le a végére
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToEnd();
        });
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final authState = ref.read(authViewModelProvider);
                final payload = authState.asData?.value.payload;
                final isMe = message.senderUser.id == payload?.userId;
                final hasText = message.content.trim().isNotEmpty;
                var hasImages = false;
                final messageAttachments = message.messageAttachments;
                if (messageAttachments != null) {
                  hasImages = messageAttachments.isNotEmpty;
                }

                Widget messageContent;
                if (hasText && hasImages) {
                  messageContent = Column(
                    crossAxisAlignment:
                        isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? Colors.blueAccent.shade200
                                  : Colors.lightBlueAccent.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MessageImagesStack(
                        images: message.messageAttachments ?? [],
                        isMe: message.senderUser.id == payload?.userId,
                      ),                    ],
                  );
                } else if (hasImages) {
                  messageContent = MessageImagesStack(
                    images: message.messageAttachments ?? [],
                    isMe: message.senderUser.id == payload?.userId,
                  );
                } else {
                  messageContent = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isMe
                              ? Colors.blueAccent.shade200
                              : Colors.lightBlueAccent.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  key: ValueKey(message.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: messageContent,
                  ),
                );
              },
            ),
          ),
          // Preview a kiválasztott képeknek
          _buildSelectedImagesPreview(),
          const Divider(height: 1),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _pickImageFromCamera,
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Írj üzenetet...',
                    ),
                    onFieldSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
