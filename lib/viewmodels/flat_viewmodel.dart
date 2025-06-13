import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/flat_status.dart';

import '../models/flat_model.dart';
import '../services/flat_service.dart';

final flatServiceProvider = Provider((ref) => FlatService());

final flatViewModelProvider =
    StateNotifierProvider<FlatViewmodel, AsyncValue<Flat?>>(
      (ref) => FlatViewmodel(ref),
    );

class FlatViewmodel extends StateNotifier<AsyncValue<Flat?>> {
  final Ref ref;

  FlatViewmodel(this.ref) : super(const AsyncValue.data(null));

  Future<List<File>?> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    return picked.isNotEmpty ? picked.map((x) => File(x.path)).toList() : null;
  }

  Future<File?> takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> save(
    BuildContext context, {
    required String address,
    required String price,
    required List<File> images,
    String? existingFlatId,
    required FlatStatus flatStatus,
  }) async {
    try {
      state = const AsyncValue.loading();
      await ref
          .read(flatServiceProvider)
          .saveFlatWithImages(
            address: address,
            price: price,
            images: images,
            existingFlatId: existingFlatId,
            status: flatStatus,
          );
      if (context.mounted) Navigator.of(context).pop();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
