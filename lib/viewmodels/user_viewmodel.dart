import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/services/user_service.dart';
import '../models/user_model.dart';

final userServiceProvider = Provider((ref) => UserService());

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
  List<String> excludedTenantIds = [];

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
    final filtered = _allTenants.where((t) => !excludedTenantIds.contains(t.id)).toList();
    state = AsyncData(filtered);
  }

  void excludeTenant(String tenantId) {
    excludedTenantIds.add(tenantId);
    _filterAndEmit();
  }

  void includeTenant(String tenantId) {
    excludedTenantIds.remove(tenantId);
    _filterAndEmit();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await loadTenants();
  }
}

