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

  Widget _buildImagesGrid(List<MessageAttachment>? images) {
    if (images == null || images.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final imageUrl = image.url; // itt már URL-t használunk

        return GestureDetector(
          onTap:
              () => showSwipeImageGallery(
                context,
                children: [NetworkImage(imageUrl)],
                swipeDismissible: true,
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image));
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    print(messages);
    ref.listen<List<MessageModel>>(messagesProvider, (previous, next) {
      if (previous?.length != next.length) {
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
                      _buildImagesGrid(message.messageAttachments),
                    ],
                  );
                } else if (hasImages) {
                  messageContent = _buildImagesGrid(message.messageAttachments);
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: messageContent,
                  ),
                );
              },
            ),
          ),
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
