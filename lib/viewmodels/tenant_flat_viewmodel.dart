import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flat_model.dart';
import '../services/flat_service.dart';
import 'auth_viewmodel.dart';

class TenantFlatViewModel extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService _service;
  final String tenantUserId;

  TenantFlatViewModel(this._service, this.tenantUserId)
    : super(const AsyncValue.loading()) {
    _fetchFlat();
  }

  Future<void> _fetchFlat() async {
    try {
      final flat = await _service.fetchFlatForTenant(tenantUserId);
      state = AsyncValue.data(flat);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /*Future<void> sendExitRequest() async {
    if (state.value == null) return;
    state = const AsyncValue.loading();
    try {
      await _service.sendExitRequest(tenantUserId, state.value!.id!);
      await _fetchFlat(); // ha szeretnéd frissíteni az adatokat
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }*/
}

// Provider a SupabaseClient-et használva (feltételezve Supabase inicializálva van máshol)
final flatServiceProvider = Provider<FlatService>((ref) {
  return FlatService();
});

final tenantUserIdProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  return currentUser?.id as String;
});

final tenantFlatViewModelProvider =
    StateNotifierProvider<TenantFlatViewModel, AsyncValue<Flat?>>((ref) {
      final service = ref.watch(flatServiceProvider);
      final userId = ref.watch(tenantUserIdProvider);
      return TenantFlatViewModel(service, userId);
    });
