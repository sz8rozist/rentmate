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
      bottomNavigationBar: CurvedNavigationBar(
        index: index,
        height: 60,
        backgroundColor: Colors.transparent,
        color: lightColorScheme.primary, // háttérszín
        buttonBackgroundColor: Colors.white, // középső gomb háttér
        animationCurve: Curves.easeInOutBack,
        animationDuration: const Duration(milliseconds: 400),
        items: [
          _navItem(icon: FontAwesome.house, selected: index == 0),
          _navItem(icon: Icons.search, selected: index == 1),
          _navItem(icon: FontAwesome.user, selected: index == 2),
        ],
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
      ),
    );
  }

  Widget _navItem({required IconData icon, required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        size: selected ? 30 : 24,
        color: selected ? lightColorScheme.secondary : Colors.white,
      ),
    );
  }
}
