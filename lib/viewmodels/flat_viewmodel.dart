import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/services/flat_service.dart';

import '../rest_api_config.dart';
import '../models/flat_model.dart';
import '../services/user_service.dart';
import 'file_upload_viewmodel.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class FlatState {
  const FlatState({
    this.flat,
    this.allTenants = const [],
  });

  final Flat? flat;
  final List<UserModel> allTenants;

  List<int> get existingTenantIds =>
      flat?.tenants?.map((t) => t.id as int).toList() ?? [];

  List<UserModel> get availableTenants =>
      allTenants.where((t) => !existingTenantIds.contains(t.id)).toList();

  FlatState copyWith({Flat? flat, List<UserModel>? allTenants}) => FlatState(
    flat: flat ?? this.flat,
    allTenants: allTenants ?? this.allTenants,
  );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class FlatViewModel extends AsyncNotifier<FlatState> {
  FlatService get _flatService => ref.read(flatServiceProvider);
  UserService get _userService => ref.read(userServiceProvider);

  @override
  Future<FlatState> build() async => const FlatState();

  // --- Képkezelés ---

  Future<List<File>?> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return null;

    final allowed = picked
        .where((x) => x.path.toLowerCase().endsWith(RegExp(r'\.(jpg|jpeg|png)$').pattern))
        .take(6)
        .map((x) => File(x.path))
        .toList();

    return allowed.isEmpty ? null : allowed;
  }

  Future<File?> takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> deleteImage(int flatId, int imageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final success = await _flatService.deleteFlatImage(imageId);
      if (!success) throw Exception('Kép törlése sikertelen');
      final updatedFlat = await _flatService.getFlatById(flatId);
      return state.requireValue.copyWith(flat: updatedFlat);
    });
  }

  // --- Tenant kezelés ---

  Future<void> searchTenants(String term) async {
    final tenants = await _userService.getTenant(term);
    final current = state.requireValue;
    state = AsyncData(current.copyWith(allTenants: tenants));
  }

  Future<void> addTenant(UserModel tenant) async {
    final current = state.requireValue;
    final flatId = current.flat?.id;
    if (flatId == null) return;

    final success = await _flatService.addTenantToFlat(flatId, tenant.id as int);
    if (!success) return;

    final updatedTenants = [...?current.flat!.tenants, tenant];
    state = AsyncData(
      current.copyWith(flat: current.flat!.copyWith(tenants: updatedTenants)),
    );
  }

  Future<void> removeTenant(int tenantId) async {
    final current = state.requireValue;
    final flatId = current.flat?.id;
    if (flatId == null) return;

    final success = await _flatService.removeTenantFromFlat(tenantId);
    if (!success) return;

    final updatedTenants =
    current.flat!.tenants!.where((t) => t.id != tenantId).toList();
    state = AsyncData(
      current.copyWith(flat: current.flat!.copyWith(tenants: updatedTenants)),
    );
  }

  Future<void> uploadImages(int flatId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    final current = state.requireValue;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final results = await Future.wait(
        filePaths.map(
              (path) => _flatService.uploadSingleImage(flatId, path).catchError((e) {
            print("Hiba a kép feltöltésénél: $path -> $e");
            return false;
          }),
        ),
      );

      final updatedFlat = await _flatService.getFlatById(flatId);

      if (!results.every((r) => r == true)) {
        print("Nem minden kép töltődött fel");
      }

      return current.copyWith(flat: updatedFlat);
    });
  }

  void clear() => state = const AsyncData(FlatState());
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final flatServiceProvider = Provider<FlatService>((ref) {
  return FlatService(
    apiService: ref.watch(apiServiceProvider),
    fileUploadService: ref.watch(fileUploadServiceProvider),
  );
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(apiServiceProvider));
});

final flatViewModelProvider =
AsyncNotifierProvider<FlatViewModel, FlatState>(FlatViewModel.new);