import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rentmate/models/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Flat>> getFlatsForCurrentUser(UserModel currentUser) async {
   /* if (currentUser.role?.value == "landlord") {
      final response = await _client
          .from('flats')
          .select(
            '*, landlord:users!landlord_user_id(*), flats_for_rent(*, tenant:users!tenant_user_id(*))',
          )
          .eq('landlord_user_id', currentUser.id);

      return (response as List)
          .map((e) => Flat.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (currentUser.role?.value == "tenant") {
      final response = await _client
          .from('flats_for_rent')
          .select('*, flat:flats(*, landlord:users!landlord_user_id(*))')
          .eq('tenant_user_id', currentUser.id);

      return (response as List).map((e) {
        final flatJson = e['flat'] as Map<String, dynamic>;
        return Flat.fromJson(flatJson);
      }).toList();
    }*/

    return List.empty();
  }

  Stream<List<MessageModel>> subscribeToMessages(int flatId) async* {
    // 1. Először figyeld a messages táblát realtime-ban
    await for (final data in _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('flat_id', flatId)
        .order('created_at')) {
      // 2. Kinyerjük az összes egyedi sender_user_id-t az üzenetekből
      final userIds =
          data.map((msg) => msg['sender_user_id'] as String).toSet().toList();

      // 3. Lekérjük a user adatokat egyszerre (feltételezve, hogy van 'users' tábla)
      final usersResponse = await _client
          .from('users')
          .select('id, name, email, role')
          .inFilter('id', userIds);
      if (usersResponse.isEmpty) {
        // Hiba esetén csak az alap UserModel id-vel térünk vissza
        yield data.map((json) {
          return MessageModel(
            id: json['id'],
            flatId: json['flat_id'],
            senderUser: UserModel(
              id: json['sender_user_id'],
              name: '',
              email: '',
            ),
            content: json['content'],
            imageUrl: json['image_urls'],
            createdAt: DateTime.parse(json['created_at']),
          );
        }).toList();
        continue;
      }

      // 4. Mapbe tesszük a user adatokat userId alapján
      final Map<String, UserModel> usersMap = {
        for (final userJson in usersResponse)
          userJson['id']: UserModel(
            id: userJson['id'],
            name: userJson['name'],
            email: userJson['email'],
            role: UserRoleExtension.fromValue(userJson['role']),
          ),
      };

      // 5. Összekapcsoljuk az üzeneteket a user adatokkal
      final messages =
          data.map((json) {
            final senderUserId = json['sender_user_id'];
            return MessageModel(
              id: json['id'],
              flatId: json['flat_id'],
              senderUser:
                  usersMap[senderUserId] ??
                  UserModel(id: senderUserId, name: '', email: '', role: null),
              content: json['content'],
              imageUrl: json['image_urls'],
              createdAt: DateTime.parse(json['created_at']),
            );
          }).toList();

      yield messages;
    }
  }

  // Üzenet küldés
  Future<void> sendMessage(
    int flatId,
    int senderUserId,
    String content,
    List<File>? files,
  ) async {
    List<String> imageUrls = [];

    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${senderUserId}_${Random().nextInt(10000)}.jpg';
        await _client.storage.from('chat-images').upload(fileName, file);
        final url = _client.storage.from('chat-images').getPublicUrl(fileName);
        imageUrls.add(url);

        // Kicsit várhatsz, hogy ne üsd túl gyorsan az uploadot (opcionális)
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // JSON string a képek URL-jeiből
    final imagesJson = imageUrls.isNotEmpty ? jsonEncode(imageUrls) : null;

    await _client.from('messages').insert({
      'flat_id': flatId,
      'sender_user_id': senderUserId,
      'content': content,
      'image_urls': imagesJson, // a mező neve: image_urls
    });
  }
}
