import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/services/user_service.dart';
import '../models/user_model.dart';

final userServiceProvider = Provider((ref) => UserService());

final tenantListProvider =
StateNotifierProvider<TenantListNotifier, AsyncValue<List<UserModel>>>((ref) {
  final service = ref.read(userServiceProvider);
  return TenantListNotifier(service);
});

class TenantListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserService service;

  TenantListNotifier(this.service) : super(const AsyncLoading()) {
    loadTenants();
  }

  Future<void> loadTenants([String name = '']) async {
    try {
      final tenant = await service.getTenant(name);
      state = AsyncData(tenant);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await loadTenants();
  }

}
