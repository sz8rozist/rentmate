enum FlatStatus { available, rented }

extension FlatStatusExtension on FlatStatus {
  String get label {
    switch (this) {
      case FlatStatus.available:
        return 'Szabad';
      case FlatStatus.rented:
        return 'Kiadva';
    }
  }

  String get value {
    switch (this) {
      case FlatStatus.available:
        return 'available';
      case FlatStatus.rented:
        return 'rented';
    }
  }

  static FlatStatus? fromValue(String value) {
    return FlatStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FlatStatus.available,
    );
  }
}
