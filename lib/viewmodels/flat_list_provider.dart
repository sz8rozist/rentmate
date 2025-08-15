import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/services/flat_service.dart';

import '../GraphQLConfig.dart';
import '../models/flat_model.dart';

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

  Future<Flat?> addFlat(String address, int price, int? userId) async {
    state = AsyncValue.loading();
    try {
      final flat = await _service.addFlat(address, price, userId);
      state = AsyncValue.data(flat); // ha Riverpod state-et használsz
      return flat;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print(e);
    }
  }

  Future<void> updateFlat(int id, Flat flat) async {
    state = AsyncValue.loading();
    try {
      final updatedFlat = await _service.updateFlat(id, flat);
      state = AsyncValue.data(updatedFlat);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFlat(int id) async {
    state = AsyncValue.loading();
    try {
      await _service.deleteFlat(id);
      state = AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Több kép feltöltése párhuzamosan
  Future<void> uploadImages(int flatId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    state = AsyncValue.loading();

    try {
      // Több kép feltöltése párhuzamosan
      final allUploaded = await _service.uploadFlatImages(flatId, filePaths);

      if (allUploaded) {
        final flat = await _service.getFlatById(flatId);
        state = AsyncValue.data(flat);
      } else {
        throw Exception('Nem sikerült minden képet feltölteni.');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
  Future<void> addTenant(int flatId, int tenantId) async {
    state = AsyncValue.loading();
    try {
      final addFlat = await _service.addTenantToFlat(flatId, tenantId);
      if (addFlat) {
        Flat? flat = await _service.getFlatById(flatId);
        state = AsyncValue.data(flat);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Tenant törlés
  Future<void> removeTenant(int flatId, int tenantId) async {
    state = AsyncValue.loading();
    try {
      final updatedFlat = await _service.removeTenantFromFlat(tenantId);
      if (updatedFlat) {
        Flat? flat = await _service.getFlatById(flatId);
        state = AsyncValue.data(flat);
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
  final client = ref.watch(graphQLClientProvider);
  return FlatService(client.value);
});

/// -----------------
/// ViewModel Providerek
/// -----------------
final flatViewModelProvider = StateNotifierProvider<FlatViewModel, AsyncValue<Flat?>>((
  ref,
) {
  return FlatViewModel(ref.watch(flatServiceProvider));
});

