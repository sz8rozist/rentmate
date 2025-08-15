import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/services/flat_service.dart';

import '../GraphQLConfig.dart';
import '../models/flat_model.dart';

// Paraméterezett provider: userId-t adunk át a Family-nek
final apartmentSelectorViewModelProvider =
StateNotifierProvider.family<ApartmentSelectorViewModel, AsyncValue<List<Flat>>, int>(
      (ref, userId) {
    final flatService = ref.watch(flatServiceProvider);
    final vm = ApartmentSelectorViewModel(flatService);
    vm.loadFlats(userId); // automatikusan betölti
    return vm;
  },
);

final flatServiceProvider = Provider<FlatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  return FlatService(client.value);
});

final selectedFlatProvider = StateProvider<Flat?>((ref) => null);

class ApartmentSelectorViewModel extends StateNotifier<AsyncValue<List<Flat>>> {
  final FlatService _flatService;

  ApartmentSelectorViewModel(this._flatService) : super(const AsyncValue.loading());

  // Lakások betöltése userId alapján
  Future<void> loadFlats(int userId) async {
    state = const AsyncValue.loading();
    try {
      final flats = await _flatService.getFlatsForLandlord(userId);
      state = AsyncValue.data(flats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
