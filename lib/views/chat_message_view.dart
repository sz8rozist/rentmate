import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/chat_view_viewmodel.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_provider.dart';
import '../widgets/swipe_image_galery.dart';

class ChatMessageView extends ConsumerStatefulWidget {
  final String flatId;

  const ChatMessageView({super.key, required this.flatId});

  @override
  ConsumerState<ChatMessageView> createState() => _ChatMessageViewState();
}

class _ChatMessageViewState extends ConsumerState<ChatMessageView> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<File> _imageFiles = [];

  void _sendMessage() async {
    final text = _controller.text.trim();

    // Ha sem kép, sem szöveg nincs, nem küldünk
    if (text.isEmpty && _imageFiles.isEmpty) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final sendMessage = ref.read(sendMessageProvider);
    await sendMessage(widget.flatId, user.id, text, _imageFiles);

    FocusScope.of(context).unfocus();

    setState(() {
      _controller.clear();
      _imageFiles.clear();
    });
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }
  Widget _buildImagesGrid(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () {
          showSwipeImageGallery(
            context,
            children: [NetworkImage(imageUrls.first)],
            swipeDismissible: true,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrls.first,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('Kép betöltési hiba')),
          ),
        ),
      );
    } else {
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
          itemBuilder: (context, imgIndex) {
            final imageUrl = imageUrls[imgIndex];
            return GestureDetector(
              onTap: () {
                showSwipeImageGallery(
                  context,
                  initialIndex: imgIndex,
                  children:
                  imageUrls.map((url) => NetworkImage(url)).toList(),
                  swipeDismissible: true,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Kép betöltési hiba')),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(messagesProvider(widget.flatId));
    final asyncUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: asyncUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nem vagy bejelentkezve'));
          }
          return asyncMessages.when(
            data: (messages) {
              messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderUser.id == user.id;

                        Widget messageContent;
                        final hasText = message.content.trim().isNotEmpty;
                        final hasImages = message.imageUrls.isNotEmpty;

                        if (hasText && hasImages) {
                          // Van szöveg és kép is: külön containerben legyen a szöveg, alatta a képek
                          messageContent = Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12), // egységes padding, nem csak bottom
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.blueAccent.shade200
                                        : Colors.lightBlueAccent.shade400,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                                      bottomRight: Radius.circular(isMe ? 0 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    message.content,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8), // kis távolság a szöveg és a kép között
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: _buildImagesGrid(message.imageUrls),
                              ),
                            ],
                          );

                        } else if (hasImages) {
                          // Csak képek
                          messageContent = _buildImagesGrid(message.imageUrls);
                        } else {
                          // Csak szöveg
                          messageContent = Text(
                            message.content,
                            style: const TextStyle(color: Colors.white),
                          );
                        }
                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                                isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 2,
                                ),
                                child: Text(
                                  message.senderUser.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        message.imageUrls.isNotEmpty
                                            ? Colors.transparent
                                            : (isMe
                                                ? Colors.blueAccent.shade200
                                                : Colors
                                                    .lightBlueAccent
                                                    .shade400),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 0,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 0 : 16,
                                      ),
                                    ),
                                  ),
                                  child: messageContent,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_imageFiles.isNotEmpty)
                              SizedBox(
                                height: 70,
                                // fix magasság, hogy ne foglaljon sok helyet
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _imageFiles.length,
                                  itemBuilder: (context, index) {
                                    final file = _imageFiles[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              file,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _imageFiles.removeAt(index);
                                                });
                                              },
                                              child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor: Colors.black54,
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: _pickImageFromCamera,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo,
                                    color: Colors.blueAccent,
                                  ),
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
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: _sendMessage,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator()),
            error:
                (error, stack) => Center(child: Text('Hiba történt: $error')),
          );
        },
        loading: () => Center(child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hiba történt: $error')),
      ),
    );
  }
}
