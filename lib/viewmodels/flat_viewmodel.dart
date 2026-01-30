import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/services/flat_service.dart';

import '../rest_api_config.dart';
import '../models/flat_model.dart';
import '../services/user_service.dart';
import 'file_upload_viewmodel.dart';

/// -----------------
/// Egy lakás ViewModel
/// -----------------
class FlatViewModel extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService _service;
  final UserService _userService;
  FlatViewModel(this._service, this._userService) : super(AsyncData(null));

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

  /// Minden tenant a rendszerből (backend)
  List<UserModel> _allTenants = [];

  /// Kivétel a már hozzáadott tenantok
  List<int?> get excludedTenantIds =>
      state.value?.tenants?.map((t) => t.id).toList() ?? [];

  Future<void> loadAllTenants([String searchTerm = '']) async {
    final tenants = await _userService.getTenant(searchTerm);
    _allTenants = tenants;
  }

  /// Tenant list a kiválasztáshoz a formban
  List<UserModel> get availableTenants {
    return _allTenants.where((t) => !excludedTenantIds.contains(t.id)).toList();
  }

  // Keresés frissítése
  Future<void> searchTenants(String term) async {
    await loadAllTenants(term);
    // Force UI update
    state = AsyncValue.data(state.value);
  }

  /// Tenant hozzáadás
  Future<void> addTenant(UserModel tenant) async {
    final flatId = state.value!.id;
    final success = await _service.addTenantToFlat(
      flatId as int,
      tenant.id as int,
    );
    if (success) {
      final updatedTenants = <UserModel>[
        ...?state.value!.tenants, // ? biztosítja, hogy null esetén kihagyja
        tenant,
      ];
      state = AsyncValue.data(state.value!.copyWith(tenants: updatedTenants));
    }
  }

  /// Tenant eltávolítás
  Future<void> removeTenant(int tenantId) async {
    final flatId = state.value!.id;
    final success = await _service.removeTenantFromFlat(tenantId);
    if (success) {
      final updatedTenants =
          state.value!.tenants!.where((t) => t.id != tenantId).toList();
      state = AsyncValue.data(state.value!.copyWith(tenants: updatedTenants));
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
  return FlatService(
    apiService: apiService,
    fileUploadService: fileUploadService,
  );
});

final userServiceProvider = Provider<UserService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserService(apiService);
});

/// -----------------
/// ViewModel Providerek
/// -----------------
final flatViewModelProvider =
    StateNotifierProvider<FlatViewModel, AsyncValue<Flat?>>((ref) {
      final flatService = ref.watch(flatServiceProvider);
      final userService = ref.watch(userServiceProvider);
      return FlatViewModel(flatService, userService);
    });
