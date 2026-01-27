import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flat_model.dart';
import '../services/flat_service.dart';
import 'flat_viewmodel.dart';

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

final tenantFlatViewModelProvider =
    StateNotifierProvider.family<TenantFlatViewModel, AsyncValue<Flat?>, int?>((
      ref,
      tenantId,
    ) {
      final service = ref.watch(flatServiceProvider);
      return TenantFlatViewModel(service, tenantId);
    });
