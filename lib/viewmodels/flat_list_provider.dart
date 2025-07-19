import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/services/auth_service.dart';
import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../models/user_model.dart';
import '../services/flat_service.dart';

final flatServiceProvider = Provider((ref) => FlatService(AuthService()));

final flatProvider = StateNotifierProvider.family<FlatNotifier, AsyncValue<Flat?>, String>((ref, flatId) {
  final service = ref.read(flatServiceProvider);
  return FlatNotifier(service, flatId);
});

class FlatNotifier extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService service;
  final String flatId;

  FlatNotifier(this.service, this.flatId) : super(const AsyncLoading()) {
    _loadFlat();
  }

  Future<void> _loadFlat() async {
    try {
      final flat = await service.getFlatById(flatId);
      state = AsyncData(flat);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<File>?> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.isEmpty) return null;

    final allowedImages = picked.where((x) {
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

      await _loadFlat();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeFlat() async {
    try {
      state = const AsyncLoading();
      await service.deleteFlat(flatId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateFlat({
    required String address,
    required FlatStatus status,
    required String price,
  }) async {
    try {
      state = const AsyncLoading();

      await service.updateFlatWithImages(
        id: flatId,
        address: address,
        price: price,
        status: status,
      );

      await _loadFlat();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateImage({
    required List<FlatImage> retainedImageUrls,
    List<File>? newImages,
  }) async {
    try {
      state = const AsyncLoading();

      await service.updateImages(
        id: flatId,
        retainedImageUrls: retainedImageUrls,
        newImages: newImages,
      );

      await _loadFlat();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addTenantToFlat(String tenantUserId) async {
    try {
      state = const AsyncLoading();
      await service.addTenantToFlat(flatId, tenantUserId);
      await _loadFlat();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeTenantFromFlat(String tenantUserId) async {
    try {
      state = const AsyncLoading();
      await service.removeTenantFromFlat(flatId, tenantUserId);
      await _loadFlat();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
