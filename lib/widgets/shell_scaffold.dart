import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import '../viewmodels/navigation_viewmodel.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          BottomNavigationBar(
            currentIndex: index,
            onTap: (i) {
              ref.read(bottomNavIndexProvider.notifier).state = i;
              switch (i) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.go('/search');
                case 2:
                  context.go('/profil');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(FontAwesome.house), label: 'Kezdőlap'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keresés'),
              BottomNavigationBarItem(icon: Icon(FontAwesome.user), label: 'Profil')
            ],
          ),
        ],
      ),
    );
  }
}
