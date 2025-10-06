import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/viewmodels/chat_view_viewmodel.dart';

import '../viewmodels/auth_viewmodel.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
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
    final viewModel = ref.read(chatViewModelProvider(widget.flatId).notifier);

    await viewModel.sendMessage(userId, text, _imageFiles.isNotEmpty ? _imageFiles : null);

    _controller.clear();
    _imageFiles.clear();
    FocusScope.of(context).unfocus();
    _scrollToEnd();
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildImagesGrid(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => showSwipeImageGallery(
          context,
          children: [NetworkImage(imageUrls.first)],
          swipeDismissible: true,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrls.first, width: 150, height: 150, fit: BoxFit.cover),
        ),
      );
    }
    final crossAxisCount = 3;
    final imageSize = 150.0;
    final spacing = 8.0;
    final rowCount = (imageUrls.length / crossAxisCount).ceil();

    return SizedBox(
      height: rowCount * imageSize + (rowCount - 1) * spacing,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return GestureDetector(
            onTap: () => showSwipeImageGallery(
              context,
              initialIndex: index,
              children: imageUrls.map((u) => NetworkImage(u)).toList(),
              swipeDismissible: true,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatViewModelProvider(widget.flatId));

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

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
                final hasImages = message.imageUrls.isNotEmpty;

                Widget messageContent;
                if (hasText && hasImages) {
                  messageContent = Column(
                    crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent.shade200
                              : Colors.lightBlueAccent.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(message.content, style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      _buildImagesGrid(message.imageUrls),
                    ],
                  );
                } else if (hasImages) {
                  messageContent = _buildImagesGrid(message.imageUrls);
                } else {
                  messageContent = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.blueAccent.shade200
                          : Colors.lightBlueAccent.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.content, style: const TextStyle(color: Colors.white)),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickImageFromCamera),
                IconButton(icon: const Icon(Icons.photo), onPressed: _pickImage),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Írj üzenetet...'),
                    onFieldSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
