import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_view_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/message_attachment.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).joinRoom(widget.flatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageFiles.isEmpty) return;

    final payload = ref.read(authViewModelProvider).asData?.value.payload;
    if (payload == null) {
      CustomSnackBar.error(context, 'Hiba: felhasználó azonosító nem elérhető');
      return;
    }

    final notifier = ref.read(chatProvider.notifier);
    final imagesToSend = List<File>.from(_imageFiles);

    // Optimista UI: azonnal töröljük az inputot
    _controller.clear();
    setState(() => _imageFiles.clear());
    FocusScope.of(context).unfocus();

    await notifier.sendMessageWithAttachments(
      flatId: widget.flatId,
      senderId: payload.userId,
      content: text,
      attachments: imagesToSend,
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imageFiles.add(File(picked.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final payload = ref.watch(authViewModelProvider).asData?.value.payload;

    // Scroll le ha új üzenet érkezik
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToEnd();
      }
    });

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                final isMe = message.senderUser.id == payload?.userId;
                return _MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isMe: isMe,
                  currentUserId: payload?.userId,
                );
              },
            ),
          ),
          _SelectedImagesPreview(
            files: _imageFiles,
            onRemove: (index) => setState(() => _imageFiles.removeAt(index)),
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

// ---------------------------------------------------------------------------
// Üzenet buborék
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
  });

  final MessageModel message;
  final bool isMe;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final hasText = message.content.trim().isNotEmpty;
    final hasImages = message.messageAttachments?.isNotEmpty ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasText) _TextBubble(content: message.content, isMe: isMe),
            if (hasText && hasImages) const SizedBox(height: 8),
            if (hasImages)
              MessageImagesStack(
                images: message.messageAttachments ?? [],
                isMe: isMe,
              ),
          ],
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.content, required this.isMe});

  final String content;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blueAccent.shade200 : Colors.lightBlueAccent.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(content, style: const TextStyle(color: Colors.white)),
    );
  }
}

// ---------------------------------------------------------------------------
// Kiválasztott képek előnézete
// ---------------------------------------------------------------------------

class _SelectedImagesPreview extends StatelessWidget {
  const _SelectedImagesPreview({
    required this.files,
    required this.onRemove,
  });

  final List<File> files;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  files[index],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}