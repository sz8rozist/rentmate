import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rentmate/models/flat_model.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class FlatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Flat>> getFlats() async {
    final response = await _supabase
        .from('flats')
        .select('*, images:flats_images(*)');
    return (response as List)
        .map((e) => Flat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteFlat(String id) async {
    //Képek lekérése
    final imageRecords = await _supabase
        .from('flats_images')
        .select('image_url')
        .eq('flat_id', id);

    //TODO: Itt valamiért a storageból nem törli a képet.
    for (final record in imageRecords) {
      final imageUrl = record['image_url'] as String;

      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      // A bucket neve 'flats', így az utána jövő rész az útvonal a bucketben (fájl vagy almappa/fájl)
      // Általános eset: bucket utáni részt kell megkapni
      final bucketIndex = segments.indexOf('flats');
      if (bucketIndex == -1 || bucketIndex == segments.length - 1) continue;

      final filePathInBucket = segments.sublist(bucketIndex + 1).join('/');

      // Fájl törlése
      await _supabase.storage.from('flats').remove([filePathInBucket]);
    }
    //flat törlése - elég csak a flatet törölni mert az idegenkulcsokra be van állítva ON DELETE CASCADE
    await _supabase.from('flats').delete().eq('id', id);
  }

  Future<void> saveFlatWithImages({
    required String address,
    required String price,
    required FlatStatus status,
    required List<File> images,
    String? existingFlatId,
    required UserModel landlord,
  }) async {
    final imageUrls = <String>[];
    // 1️⃣ Képek feltöltése Storage-be
    for (final image in images) {
      final fileName =
          'flat_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from('flats')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from('flats').getPublicUrl(fileName);
      imageUrls.add(publicUrl);
    }

    // 2️⃣ Lakás beszúrás vagy frissítés
    late String flatId;

    if (existingFlatId == null) {
      final insertResponse =
          await _supabase
              .from('flats')
              .insert({
                'address': address,
                'price': price,
                'status': FlatStatus.active.value,
                'landlord_user_id': landlord.id,
              })
              .select('id')
              .single();

      flatId = insertResponse['id'] as String;
    } else {
      await _supabase
          .from('flats')
          .update({'address': address, 'price': price, 'status': status.value})
          .eq('id', existingFlatId);
    }

    // 4️⃣ Képek beszúrása flat_images táblába
    final imageRecords =
        imageUrls.map((url) => {'flat_id': flatId, 'image_url': url}).toList();

    if (imageRecords.isNotEmpty) {
      await _supabase.from('flats_images').insert(imageRecords);
    }
  }
}
