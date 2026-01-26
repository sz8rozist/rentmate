import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
import 'package:rentmate/widgets/app_bar.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final List<Widget>? actions;

  const ShellScaffold({super.key, required this.child, this.actions});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  int _selectedIndex = 0;

  /// Navigáció a kiválasztott index alapján
  void _onItemTapped(int index, UserRole role, String flatId) {
    setState(() {
      _selectedIndex = index;
    });

    if (role == UserRole.landlord) {
      switch (index) {
        case 0:
          context.goNamed(AppRoute.flat.name);
          break;
        case 1:
          context.goNamed(AppRoute.chatMessage.name);
          break;
        case 2:
          context.goNamed(AppRoute.profil.name);
          break;
        case 3:
          context.goNamed(AppRoute.home.name);
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.goNamed(AppRoute.home.name);
          break;
        case 1:
          context.goNamed(AppRoute.chatMessage.name);
          break;
        case 2:
          context.goNamed(AppRoute.myRental.name);
          break;
        case 3:
          context.goNamed(AppRoute.invoices.name);
          break;
        case 4:
          context.goNamed(
            AppRoute.documents.name,
            pathParameters: {"flatId": flatId},
          );
          break;
        case 5:
          context.goNamed(AppRoute.profil.name);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;
    final role = payload?.role;
    final selectedFlat = ref.watch(selectedFlatProvider);

    if (selectedFlat == null || role == null) {
      return const SizedBox();
    }

    final flatId = selectedFlat.id;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBarWidget(actions: widget.actions),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg-2.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                color:
                    isDarkMode
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.15),
              ),
            ),
            widget.child,
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // fix szélesség az ikonoknak
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        showUnselectedLabels: true,
        onTap: (index) => _onItemTapped(index, role, flatId.toString()),
        items: _buildBottomNavItems(role),
      ),

    );
  }

  /// Role-alapú menüpontok a bottom nav barhoz
  List<BottomNavigationBarItem> _buildBottomNavItems(UserRole role) {
    if (role == UserRole.landlord) {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.house), label: 'Lakásom'),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Üzenetek'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        const BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Továbbiak'),
      ];
    } else {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Kezdőlap'),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Üzenetek'),
        const BottomNavigationBarItem(icon: Icon(Icons.house), label: 'Albérletem'),
        const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Számlák'),
        const BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Dokumentumok'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }
}
