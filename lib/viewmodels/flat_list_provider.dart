import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/services/flat_service.dart';

import '../rest_api_config.dart';
import '../models/flat_model.dart';
import 'file_upload_viewmodel.dart';

/// -----------------
/// Egy lakás ViewModel
/// -----------------
class FlatViewModel extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService _service;

  FlatViewModel(this._service) : super(AsyncData(null));

  /*Future<void> loadFlat(int id) async {
    try {
      final flat = await _service.getFlatById(id);
      state = flat;
    } catch (_) {
      state = null;
    }
  }*/

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

  /// Kép törlés
  Future<void> deleteImage(int flatId, int imageId) async {
    state = AsyncValue.loading();
    try {
      final updatedFlat = await _service.deleteFlatImage(imageId);
      if (updatedFlat) {
        Flat? flat = await _service.getFlatById(flatId);
        state = AsyncValue.data(flat);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Tenant hozzáadás
  Future<void> addTenant(int flatId, int tenantId, UserModel tenant) async {
    final currentFlat = state.value;
    if (currentFlat == null) return;

    state = const AsyncValue.loading();

    try {
      final success = await _service.addTenantToFlat(flatId, tenantId);

      if (success) {
        final List<UserModel> updatedTenants = [
          ...(currentFlat.tenants ?? <UserModel>[]),
          tenant,
        ];

        state = AsyncValue.data(
          currentFlat.copyWith(tenants: updatedTenants),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  /// Tenant törlés
  Future<void> removeTenant(int tenantId) async {
    final currentFlat = state.value;
    if (currentFlat == null) return;

    state = const AsyncValue.loading();

    try {
      final success = await _service.removeTenantFromFlat(tenantId);

      if (success) {
        final updatedTenants = currentFlat.tenants
            ?.where((t) => t.id != tenantId)
            .toList();

        state = AsyncValue.data(
          currentFlat.copyWith(tenants: updatedTenants),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  void clear() => state = AsyncValue.data(null);
}

/// -----------------
/// Service Provider
/// -----------------
final flatServiceProvider = Provider<FlatService>((ref) {
  final fileUploadService = ref.watch(fileUploadServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return FlatService(apiService: apiService, fileUploadService: fileUploadService);
});

/// -----------------
/// ViewModel Providerek
/// -----------------
final flatViewModelProvider =
    StateNotifierProvider<FlatViewModel, AsyncValue<Flat?>>((ref) {
      return FlatViewModel(ref.watch(flatServiceProvider));
    });
