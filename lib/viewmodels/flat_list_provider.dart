import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flat_model.dart';
import '../services/flat_service.dart';

final flatServiceProvider = Provider((ref) => FlatService());

final flatListProvider =
    StateNotifierProvider<FlatListNotifier, AsyncValue<List<Flat>>>((ref) {
      final service = ref.read(flatServiceProvider);
      return FlatListNotifier(service);
    });

class FlatListNotifier extends StateNotifier<AsyncValue<List<Flat>>> {
  final FlatService service;

  FlatListNotifier(this.service) : super(const AsyncLoading()) {
    loadFlats();
  }

  Future<void> loadFlats() async {
    try {
      final flats = await service.getFlats();
      state = AsyncData(flats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeFlat(Flat flat) async {
    try {
      await service.deleteFlat(flat.id!);
      state = AsyncData([...state.value!..remove(flat)]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await loadFlats();
  }
}
