import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/services/flat_service.dart';

import '../models/flat_model.dart';
import 'auth_viewmodel.dart';

final apartmentSelectorViewModelProvider =
    StateNotifierProvider<ApartmentSelectorViewModel, AsyncValue<List<Flat>>>((
      ref,
    ) {
      final flatService = ref.watch(flatServiceProvider);
      return ApartmentSelectorViewModel(flatService);
    });

final flatServiceProvider = Provider<FlatService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FlatService(authService);
});

final selectedFlatProvider = StateProvider<Flat?>((ref) => null);

class ApartmentSelectorViewModel extends StateNotifier<AsyncValue<List<Flat>>> {
  final FlatService _flatService;

  ApartmentSelectorViewModel(this._flatService) : super(const AsyncLoading()) {
    loadFlats();
  }

  Future<void> loadFlats() async {
    try {
      final flats = await _flatService.getFlatsForCurrentLandlord();
      state = AsyncData(flats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
