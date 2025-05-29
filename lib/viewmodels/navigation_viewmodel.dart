import 'package:riverpod/riverpod.dart';

// Provider, ami a kiválasztott tab indexet tárolja
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
