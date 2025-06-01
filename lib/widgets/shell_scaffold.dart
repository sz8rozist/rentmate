import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/theme/theme.dart';
import '../viewmodels/navigation_viewmodel.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Kezdőlap';
      case 1:
        return 'Keresés';
      case 2:
        return 'Profil';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    final title = _getTitle(index);

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          // Felső sáv
          SizedBox(
            height: 80,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/bg1.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black.withOpacity(0.4),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tartalom
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.05),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),

      // Curved Bottom Navigation Bar with animation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          ref.read(bottomNavIndexProvider.notifier).state = i;
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/profil');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(FontAwesome.house), label: 'Kezdőlap'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keresés'),
          BottomNavigationBarItem(icon: Icon(FontAwesome.user), label: 'Profil'),
        ],
      ),
    );
  }
}
