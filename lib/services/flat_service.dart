import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rentmate/models/flat_image.dart';
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

      String filePathInBucket = extractFilePathFromUrl(imageUrl);

      // Fájl törlése
      await _supabase.storage.from('flats').remove([filePathInBucket]);
    }
    //flat törlése - elég csak a flatet törölni mert az idegenkulcsokra be van állítva ON DELETE CASCADE
    await _supabase.from('flats').delete().eq('id', id);
  }

  String extractFilePathFromUrl(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;

    // A bucket neve 'flats', így az utána jövő rész az útvonal a bucketben (fájl vagy almappa/fájl)
    // Általános eset: bucket utáni részt kell megkapni
    final bucketIndex = segments.indexOf('flats');

    final filePathInBucket = segments.sublist(bucketIndex + 1).join('/');
    return filePathInBucket;
  }

  Future<void> saveFlatWithImages({
    required String address,
    required String price,
    required FlatStatus status,
    required List<File> images,
    required UserModel landlord,
  }) async {
    final imageUrls = <String>[];
    // 1️⃣ Képek feltöltése Storage-be
    for (final image in images) {
      String publicUrl = await uploadImageToSupabase(image);
      imageUrls.add(publicUrl);
    }

    // 2️⃣ Lakás beszúrás vagy frissítés
    late String flatId;

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

    // 4️⃣ Képek beszúrása flat_images táblába
    final imageRecords =
        imageUrls.map((url) => {'flat_id': flatId, 'image_url': url}).toList();

    if (imageRecords.isNotEmpty) {
      await _supabase.from('flats_images').insert(imageRecords);
    }
  }

  Future<String> uploadImageToSupabase(File image) async {
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
    return publicUrl;
  }

  //TODO: A képet a storageból valamiér nem törli ezt meg kell nézni.
  Future<void> updateFlatWithImages({
    required String id,
    required String address,
    required String price,
    required List<FlatImage>
    retainedImageUrls, // a felhasználó által megtartott képek URL-jei
    List<File>? newImages, // újonnan feltöltendő képek
    required FlatStatus status,
  }) async {
    final responseGet = await _supabase
        .from('flats_images')
        .select('image_url')
        .eq('flat_id', id);

    List<String> oldImages = [];

    if (responseGet != null && responseGet.isNotEmpty) {
      for (final record in responseGet) {
        final imageUrl = record['image_url'] as String?;
        if (imageUrl != null) {
          oldImages.add(imageUrl);
        }
      }
    }

    // 2. Feltöltjük az új képeket
    List<String> newImagesUrls = [];

    if (newImages != null && newImages.isNotEmpty) {
      for (final image in newImages) {
        final uploadedUrl = await uploadImageToSupabase(image);
        newImagesUrls.add(uploadedUrl);
      }
    }

    // 3. A megtartott képek URL-jeinek kinyerése a FlatImage objektumokból
    final retainedUrls = retainedImageUrls.map((fi) => fi.imageUrl).toList();

    // 4. Meghatározzuk a törlendő képeket (amik benne voltak régen, de most nincsenek megtartva)
    final toDelete =
        oldImages.where((url) => !retainedUrls.contains(url)).toList();

    // 5. Töröljük a képeket a Storage-ból
    for (final url in toDelete) {
      try {
        final fileName = extractFilePathFromUrl(url);
        await _supabase.storage.from('flats').remove([fileName]);
      } catch (e) {
        print('Exception during image deletion: $e');
      }
    }

    // 6. Töröljük a képeket a flats_images táblából
    if (toDelete.isNotEmpty) {
      await _supabase
          .from('flats_images')
          .delete()
          .eq('flat_id', id)
          .inFilter('image_url', toDelete);
    }

    // 7. Beszúrjuk az új képeket a flats_images táblába
    if (newImagesUrls.isNotEmpty) {
      final newImageRecords =
          newImagesUrls
              .map((url) => {'flat_id': id, 'image_url': url})
              .toList();

      await _supabase.from('flats_images').insert(newImageRecords);
    }

    // 8. Frissítjük a flats rekordot az új adatokkal (kép lista nélkül, mert külön táblában vannak)
    final updates = {
      'address': address,
      'price': price,
      'status': status.value,
    };

    await _supabase.from('flats').update(updates).eq('id', id);
  }
}
