import 'package:flutter_riverpod/flutter_riverpod.dart';
// Provider, ami a kiválasztott tab indexet tárolja
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
