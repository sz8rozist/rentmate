enum FlatStatus { active, inactive }

extension FlatStatusExtension on FlatStatus {
  String get label {
    switch (this) {
      case FlatStatus.active:
        return 'Szabad';
      case FlatStatus.inactive:
        return 'Kiadva';
    }
  }

  String get value {
    switch (this) {
      case FlatStatus.active:
        return 'szabad';
      case FlatStatus.inactive:
        return 'kiadva';
    }
  }

  static FlatStatus? fromValue(String value) {
    return FlatStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FlatStatus.active,
    );
  }
}
