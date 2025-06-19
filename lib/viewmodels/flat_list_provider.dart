import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/flat_image.dart';

import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../services/flat_service.dart';

final flatServiceProvider = Provider((ref) => FlatService());

final flatListProvider =
    StateNotifierProvider<FlatListNotifier, AsyncValue<List<Flat>>>((ref) {
      final service = ref.read(flatServiceProvider);
      return FlatListNotifier(service);
    });

class FlatListNotifier extends StateNotifier<AsyncValue<List<Flat>>> {
  final FlatService service;

  FlatListNotifier(this.service) : super(const AsyncLoading()) {
    loadFlats();
  }

  Future<void> loadFlats() async {
    try {
      state = AsyncLoading();
      final flats = await service.getFlats();
      state = AsyncData(flats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<File>?> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.isEmpty) return null;

    final allowedImages =
        picked.where((x) {
          final path = x.path.toLowerCase();
          return path.endsWith('.jpg') ||
              path.endsWith('.jpeg') ||
              path.endsWith('.png');
        }).toList();

    if (allowedImages.length > 6) {
      return allowedImages.sublist(0, 6).map((x) => File(x.path)).toList();
    }

    return allowedImages.map((x) => File(x.path)).toList();
  }

  Future<File?> takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> saveFlat({
    required String address,
    required String price,
    required List<File> images,
    required FlatStatus flatStatus,
    required UserModel landlord,
  }) async {
    try {
      state = const AsyncLoading();

      await service.saveFlatWithImages(
        address: address,
        price: price,
        images: images,
        status: flatStatus,
        landlord: landlord,
      );

      await loadFlats(); // Frissítjük az adatokat mentés után
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeFlat(Flat flat) async {
    try {
      await service.deleteFlat(flat.id!);
      // A lista frissítése, eltávolítjuk a törölt elemet
      state = AsyncData([...state.value!..remove(flat)]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await loadFlats();
  }

  Future<void> updateFlat({
    required String flatId,
    required String address,
    required FlatStatus status,
    required String price,
  }) async {
    try {
      state = const AsyncLoading();

      // Meghívjuk a service update metódusát
      await service.updateFlatWithImages(
        id: flatId,
        address: address,
        price: price,
        status: status,
      );

      // Frissítjük a listát a mentés után
      await loadFlats();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateImage({
    required String flatId,
    required List<FlatImage>
    retainedImageUrls, // a felhasználó által megtartott képek URL-jei
    List<File>? newImages, // újonnan feltöltendő képek
  }) async {
    try {
      state = const AsyncLoading();

      await service.updateImages(
        id: flatId,
        retainedImageUrls: retainedImageUrls,
        newImages: newImages,
      );

      await loadFlats();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addTenantToFlat(String flatId, String tenantUserId) async {
    try {
      state = const AsyncLoading();
      await service.addTenantToFlat(flatId, tenantUserId);
      await loadFlats();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeTenantFromFlat(String flatId, String tenantUserId) async {
    try {
      state = const AsyncLoading();
      await service.removeTenantFromFlat(flatId, tenantUserId);
      await loadFlats();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
