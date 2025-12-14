import 'package:flutter/material.dart';
import 'package:rentmate/widgets/swipe_image_galery.dart';
import '../models/message_attachment.dart';

class MessageImagesStack extends StatelessWidget {
  final List<MessageAttachment> images;
  final bool isMe; // true ha a felhasználó küldte

  const MessageImagesStack({super.key, required this.images, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Maximum 3 kép egymásra
    final displayImages = images.length > 3 ? images.sublist(0, 3) : images;

    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          ...List.generate(displayImages.length, (index) {
            final image = displayImages[index];
            return Positioned(
              left: isMe ? null : index * 30.0, // balra tolás, ha nem az én üzenetem
              right: isMe ? index * 30.0 : null, // jobbra tolás, ha az én üzenetem
              child: GestureDetector(
                onTap: () => showSwipeImageGallery(
                  context,
                  children: images.map((e) => NetworkImage(e.url)).toList(),
                  initialIndex: index,
                  swipeDismissible: true,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image.url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image));
                    },
                  ),
                ),
              ),
            );
          }),
          // Ha több mint 3 kép, mutatjuk a +x jelzést
          if (images.length > 3)
            Positioned(
              left: isMe ? null : 3 * 30.0,
              right: isMe ? 3 * 30.0 : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${images.length - 3}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
