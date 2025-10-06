import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../GraphQLConfig.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

final userServiceProvider = Provider<UserService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  return UserService(client.value);
});

final tenantListProvider =
    StateNotifierProvider<TenantListNotifier, AsyncValue<List<UserModel>>>((
      ref,
    ) {
      final service = ref.read(userServiceProvider);
      return TenantListNotifier(service);
    });

class TenantListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserService service;
  List<UserModel> _allTenants = [];
  List<int> excludedTenantIds = [];

  TenantListNotifier(this.service) : super(const AsyncLoading()) {
    loadTenants();
  }

  Future<void> loadTenants([String name = '']) async {
    try {
      final tenants = await service.getTenant(name);
      _allTenants = tenants;
      _filterAndEmit();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _filterAndEmit() {
    final filtered =
        _allTenants.where((t) => !excludedTenantIds.contains(t.id)).toList();
    state = AsyncData(filtered);
  }

  void excludeTenant(int tenantId) {
    excludedTenantIds.add(tenantId);
    _filterAndEmit();
  }

  void includeTenant(int tenantId) {
    excludedTenantIds.remove(tenantId);
    _filterAndEmit();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await loadTenants();
  }
}
