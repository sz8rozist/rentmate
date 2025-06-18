import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';

import 'package:rentmate/views/chat_message_view.dart';
import '../models/flat_image.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

final dummyFlats = <Flat>[
  Flat(
    id: 'flat1',
    address: 'Kossuth Lajos utca 5.',
    price: 120000,
    status: FlatStatus.active,
    landLord: 'landlord1',
    images: [
      FlatImage(imagePath: 'img2', imageUrl: 'https://picsum.photos/200/301'),
    ],
    tenants: [
      UserModel(
        id: 'tenant1',
        email: 'janez@example.com',
        name: 'János',
        role: UserRole.tenant,
      ),
      UserModel(
        id: 'tenant2',
        email: 'szilvia@example.com',
        name: 'Szilvia',
        role: UserRole.tenant,
      ),
    ],
  ),
  Flat(
    id: 'flat2',
    address: 'Petőfi Sándor utca 12.',
    price: 100000,
    status: FlatStatus.inactive,
    landLord: 'landlord1',
    images: [
      FlatImage(imagePath: 'img2', imageUrl: 'https://picsum.photos/200/301'),
    ],
    tenants: [
      UserModel(
        id: 'tenant3',
        email: 'laszlo@example.com',
        name: 'László',
        role: UserRole.tenant,
      ),
    ],
  ),
];

class _ChatViewState extends ConsumerState<ChatView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dummyFlats.length,
        itemBuilder: (context, index) {
          final flat = dummyFlats[index];

          if (flat.tenants == null || flat.tenants!.isEmpty) {
            return const SizedBox.shrink();
          }

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.teal.shade50,
              collapsedBackgroundColor: Colors.white,
              title: Text(
                flat.address,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.teal.shade900,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${flat.price} Ft/hó',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: flat.tenants!.map((tenant) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.teal.shade300,
                      child: Text(
                        tenant.name.isNotEmpty ? tenant.name[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    title: Text(
                      tenant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(tenant.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
                      onPressed: () {
                        context.pushNamed(AppRoute.chatMessage.name, pathParameters: {"tenantId": tenant.id});
                      },
                    ),
                    onTap: () {
                      context.pushNamed(AppRoute.chatMessage.name, pathParameters: {"tenantId": tenant.id});
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
