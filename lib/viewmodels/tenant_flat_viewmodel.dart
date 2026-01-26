import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/viewmodels/file_upload_viewmodel.dart';
import '../rest_api_config.dart';
import '../models/flat_model.dart';
import '../services/flat_service.dart';

class TenantFlatViewModel extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService _service;

  TenantFlatViewModel(this._service, int? tenantId)
    : super(const AsyncValue.data(null)) {
    _fetchFlat(tenantId);
  }

  Future<void> _fetchFlat(int? id) async {
    try {
      if (id == null) {
        state = AsyncValue.data(null);
        return;
      }
      final flat = await _service.getFlatForTenant(id);
      state = AsyncValue.data(flat);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final flatServiceProvider = Provider<FlatService>((ref) {
  final client = ref.watch(apiServiceProvider);
  final fileUploadService = ref.watch(fileUploadServiceProvider);
  return FlatService(apiService: client, fileUploadService: fileUploadService);
});

final tenantFlatViewModelProvider =
    StateNotifierProvider.family<TenantFlatViewModel, AsyncValue<Flat?>, int?>((
      ref,
      tenantId,
    ) {
      final service = ref.watch(flatServiceProvider);
      return TenantFlatViewModel(service, tenantId);
    });
