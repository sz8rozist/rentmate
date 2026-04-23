import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/models/flat_model.dart';

import '../models/flat_status.dart';
import 'flat_viewmodel.dart';

class ApartmentState {
  final Flat? active;
  final List<Flat> apartments;
  final bool isLoading;
  final String? error;

  ApartmentState({
    this.active,
    this.apartments = const [],
    this.isLoading = false,
    this.error,
  });

  ApartmentState copyWith({
    Flat? active,
    List<Flat>? apartments,
    bool? isLoading,
    String? error,
  }) {
    return ApartmentState(
      active: active ?? this.active,
      apartments: apartments ?? this.apartments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ApartmentNotifier extends Notifier<ApartmentState> {

  late final _flatService = ref.read(flatServiceProvider);

  @override
  ApartmentState build() {
    return ApartmentState();
  }

  Future<void> loadFlats(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final flats = await _flatService.getFlatsForLandlord(userId);

      state = state.copyWith(
        apartments: flats,
        active: flats.isNotEmpty ? flats.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addFlat(String address, int price, int userId) async {
    try {
      final flat = await _flatService.addFlat(address, price, userId);

      state = state.copyWith(
        apartments: [...state.apartments, flat],
        active: flat,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateFlat(
      int id,
      String address,
      int price,
      FlatStatus status,
      ) async {
    try {
      final updatedFlat = await _flatService.updateFlat(
        id,
        address: address,
        price: price,
        status: status,
      );

      final updatedList = state.apartments
          .map((f) => f.id == id ? updatedFlat : f)
          .toList();

      state = state.copyWith(
        apartments: updatedList,
        active: state.active?.id == id ? updatedFlat : state.active,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFlat(int id) async {
    try {
      await _flatService.deleteFlat(id);

      final updatedList =
      state.apartments.where((f) => f.id != id).toList();

      state = state.copyWith(
        apartments: updatedList,
        active: state.active?.id == id ? null : state.active,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setActive(Flat apt) {
    state = state.copyWith(active: apt);
  }
}

final apartmentProvider =
NotifierProvider<ApartmentNotifier, ApartmentState>(
    ApartmentNotifier.new);