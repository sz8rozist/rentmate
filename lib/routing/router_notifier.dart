import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/models/user_model.dart';

import '../viewmodels/auth_viewmodel.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (previous, next) {
      notifyListeners();
    });
  }
}
