import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final VoidCallback? onBack;
  const AppBarWidget({super.key, this.actions, this.onBack});
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // fehér háttér
      elevation: 5, // enyhe árnyék a háttér fölött
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary), // ikonok színe
      leading: onBack != null ?
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ) : null,
      title: Text(
        getTitleFromState(context),
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white70,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

String getTitleFromState(BuildContext context) {
  final location = GoRouter.of(context).state.matchedLocation;
  final routeNameString =
      location.split('/').where((e) => e.isNotEmpty).firstOrNull ??
          'notFound';
  final route = AppRoute.values.firstWhere(
        (r) => r.name == routeNameString,
    orElse: () => AppRoute.notFound,
  );
  return route.title();
}