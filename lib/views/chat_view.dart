import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/viewmodels/chat_view_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';

import '../models/flat_image.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../routing/app_router.dart';

class ChatView extends ConsumerStatefulWidget {
  final UserModel loggedInUser;

  const ChatView({super.key, required this.loggedInUser});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.refresh(flatsProvider(widget.loggedInUser));
  }
  @override
  Widget build(BuildContext context) {
    final flatsAsync = ref.watch(flatsProvider(widget.loggedInUser));
    return Scaffold(
      body: flatsAsync.when(
        data: (flats) {
          if (flats.isEmpty) {
            return const Center(child: Text('Nincs találat.'));
          }
          return ListView.builder(
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(flat.address),
                  subtitle: Text(
                    flat.tenants != null && flat.tenants!.isNotEmpty
                        ? flat.tenants!.map((tenant) => tenant.name).join(', ')
                        : 'Nincsenek bérlők',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    // Amikor rákattintasz a flat-re, akkor nyisd meg a chat szobát
                    // Például ide irányítasz a tenantok chat-jére vagy a flat chat oldalára
                    if(flat.tenants!.isEmpty){
                      ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar.error("Ehhez a lakáshoz nem tartoznak albérlők"));
                    }else{
                      context.pushNamed(
                        AppRoute.chatMessage.name,
                        pathParameters: {"flatId": flat.id ?? ''},
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => Center(child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator()),
        error: (error, stackTrace) {
          debugPrint('Error in flatsProvider: $error');
          debugPrintStack(stackTrace: stackTrace);
          return Center(child: Text('Hiba történt: $error'));
        },
      ),
    );
  }
}
