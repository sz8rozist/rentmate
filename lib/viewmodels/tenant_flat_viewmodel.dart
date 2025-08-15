import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../GraphQLConfig.dart';
import '../models/flat_model.dart';
import '../services/flat_service.dart';

class TenantFlatViewModel extends StateNotifier<AsyncValue<Flat?>> {
  final FlatService _service;

  TenantFlatViewModel(this._service)
    : super(const AsyncValue.data(null));

  Future<void> _fetchFlat(int id) async {
    try {
      final flat = await _service.getFlatForTenant(id);
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

final flatServiceProvider = Provider<FlatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  return FlatService(client.value);
});


final tenantFlatViewModelProvider =
    StateNotifierProvider<TenantFlatViewModel, AsyncValue<Flat?>>((ref) {
      final service = ref.watch(flatServiceProvider);
      return TenantFlatViewModel(service);
    });
