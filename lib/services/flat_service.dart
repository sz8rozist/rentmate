import 'dart:io';
import 'package:rentmate/models/flat_model.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveFlatWithImages({
    required String address,
    required String price,
    required FlatStatus status,
    required List<File> images,
    String? existingFlatId,
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
              })
              .select('id')
              .single();

      flatId = insertResponse['id'] as String;
    } else {
      Flat exsistingFlat =
          _supabase.from('flats').select().eq('id', existingFlatId).single()
              as Flat;
      flatId = exsistingFlat.id as String;
      await _supabase
          .from('flats')
          .update({'address': address, 'price': price, 'status': status.value})
          .eq('id', flatId);
    }

    // 4️⃣ Képek beszúrása flat_images táblába
    final imageRecords =
        imageUrls.map((url) => {'flat_id': flatId, 'image_url': url}).toList();

    if (imageRecords.isNotEmpty) {
      await _supabase.from('flat_images').insert(imageRecords);
    }
  }
}
