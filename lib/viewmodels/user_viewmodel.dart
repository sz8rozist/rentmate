import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../rest_api_config.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TenantListState {
  const TenantListState({
    this.allTenants = const [],
    this.excludedIds = const [],
    this.searchTerm = '',
  });

  final List<UserModel> allTenants;
  final List<int> excludedIds;
  final String searchTerm;

  /// A View ezt kapja — szűrt lista
  List<UserModel> get visibleTenants =>
      allTenants.where((t) => !excludedIds.contains(t.id)).toList();

  TenantListState copyWith({
    List<UserModel>? allTenants,
    List<int>? excludedIds,
    String? searchTerm,
  }) =>
      TenantListState(
        allTenants: allTenants ?? this.allTenants,
        excludedIds: excludedIds ?? this.excludedIds,
        searchTerm: searchTerm ?? this.searchTerm,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class TenantListNotifier extends AsyncNotifier<TenantListState> {
  UserService get _service => ref.read(userServiceProvider);

  @override
  Future<TenantListState> build() async {
    final tenants = await _service.getTenant('');
    return TenantListState(allTenants: tenants);
  }

  // --- Keresés ---

  Future<void> search(String term) async {
    // Keresés közben a régi lista megmarad, csak frissítjük
    final current = state.valueOrNull ?? const TenantListState();
    state = AsyncData(current.copyWith(searchTerm: term));

    final tenants = await _service.getTenant(term);
    state = AsyncData(
      (state.valueOrNull ?? const TenantListState()).copyWith(
        allTenants: tenants,
        searchTerm: term,
      ),
    );
  }

  // --- Szűrés ---

  void excludeTenant(int tenantId) => _updateExcluded(
        (ids) => [...ids, tenantId],
  );

  void includeTenant(int tenantId) => _updateExcluded(
        (ids) => ids.where((id) => id != tenantId).toList(),
  );

  void setExcludedIds(List<int> ids) {
    final current = state.valueOrNull ?? const TenantListState();
    state = AsyncData(current.copyWith(excludedIds: ids));
  }

  // --- Refresh ---

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const TenantListState();
    state = await AsyncValue.guard(() async {
      final tenants = await _service.getTenant(current.searchTerm);
      return current.copyWith(allTenants: tenants);
    });
  }

  // --- Helper ---

  void _updateExcluded(List<int> Function(List<int>) updater) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(excludedIds: updater(current.excludedIds)));
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(apiServiceProvider));
});

final tenantListProvider =
AsyncNotifierProvider<TenantListNotifier, TenantListState>(
  TenantListNotifier.new,
);