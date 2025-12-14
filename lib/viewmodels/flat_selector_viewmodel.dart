import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/services/flat_service.dart';

import '../GraphQLConfig.dart';
import '../models/flat_model.dart';

final flatSelectorViewModelProvider = StateNotifierProvider.family<
  FlatSelectorViewmodel,
  AsyncValue<List<Flat>>,
  int?
>((ref, userId) {
  final flatService = ref.watch(flatServiceProvider);
  final viewModel = FlatSelectorViewmodel(flatService, userId);
  return viewModel;
});
final flatServiceProvider = Provider<FlatService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  return FlatService(client.value);
});

final selectedFlatProvider = StateProvider<Flat?>((ref) => null);

class FlatSelectorViewmodel extends StateNotifier<AsyncValue<List<Flat>>> {
  final FlatService _flatService;
  final int? _userId;

  FlatSelectorViewmodel(this._flatService, this._userId)
    : super(const AsyncValue.data([])) {
    loadFlats();
  }

  // Lakások betöltése userId alapján
  Future<void> loadFlats() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final flats = await _flatService.getFlatsForLandlord(_userId);
      print(flats);
      state = AsyncValue.data(flats);
    } catch (e, st) {
      print("GraphQL Error: $e");
      state = AsyncValue.error(e, st);
    }
  }

  // Új flat hozzáadása a listához
  Future<Flat?> addFlat(String address, int price, int? userId) async {
    try {
      final flat = await _flatService.addFlat(address, price, userId);

      final previous = state.value ?? [];
      state = AsyncValue.data([...previous, flat]);

      return flat;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // Flat frissítése a listában
  Future<void> updateFlat(int id, Flat flat) async {
    try {
      final updatedFlat = await _flatService.updateFlat(id, flat);

      final previous = state.value ?? [];
      final updatedList =
          previous.map((f) => f.id == id ? updatedFlat : f).toList();
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Flat törlése a listából
  Future<void> deleteFlat(int id) async {
    try {
      await _flatService.deleteFlat(id);

      final previous = state.value ?? [];
      final updatedList = previous.where((f) => f.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Több kép feltöltése párhuzamosan
  Future<void> uploadImages(int flatId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    final previousFlats = state.value ?? [];

    // Loading állapot, de a régi adat megmarad
    state = const AsyncValue.loading();

    try {
      // Párhuzamos feltöltés minden fájlra
      final results = await Future.wait(
        filePaths.map(
          (path) =>
              _flatService.uploadSingleImage(flatId, path).catchError((e) {
                print("Hiba a kép feltöltésénél: $path -> $e");
                return false; // hibát is kezelünk, de nem dobunk
              }),
        ),
      );

      // Ellenőrizzük, hány sikerült
      final allUploaded = results.every((r) => r == true);

      // Frissítjük a flat-et
      final updatedFlat = await _flatService.getFlatById(flatId);

      final updatedList =
          previousFlats.map((f) => f.id == flatId ? updatedFlat : f).toList();
      state = AsyncValue.data(updatedList);

      if (!allUploaded) {
        // UI-nak jelezhetjük, hogy nem minden kép sikerült
        print("Nem sikerült minden képet feltölteni.");
      }
    } catch (e, st) {
      print("GraphQL Error: $e");
      state = AsyncValue.error(e, st);
    }
  }
}
