import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
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
          context.goNamed(AppRoute.home.name);
          break;
        case 1:
          context.goNamed(AppRoute.chatMessage.name);
          break;
        case 2:
          context.goNamed(AppRoute.flat.name);
          break;
        case 3:
          context.goNamed(AppRoute.profil.name);
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

  String getTitleFromState(BuildContext context, UserRole role) {
    final location = GoRouter.of(context).state.matchedLocation;
    final routeNameString =
        location.split('/').where((e) => e.isNotEmpty).firstOrNull ?? 'notFound';
    final route = AppRoute.values.firstWhere(
          (r) => r.name == routeNameString,
      orElse: () => AppRoute.notFound,
    );
    return route.title(role);
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
      appBar: PreferredSize(
        preferredSize:
        Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: Container(
          width: double.infinity,
          height: 80 + MediaQuery.of(context).padding.top,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header-image.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    getTitleFromState(context, role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.actions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.actions!,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background.withOpacity(0.3),
        child: widget.child,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        backgroundColor:
        isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white70,
        currentIndex: _selectedIndex,
        unselectedItemColor:
        isDarkMode ? Colors.grey[400] : Colors.grey[700],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => _onItemTapped(index, role, flatId.toString()),
        items: _buildNavigationItems(role),
      ),
    );
  }

  /// Role-alapú menüpontok a bottom nav barhoz
  List<CrystalNavigationBarItem> _buildNavigationItems(UserRole role) {
    if (role == UserRole.landlord) {
      return [
        CrystalNavigationBarItem(
          icon: Icons.home,
          unselectedIcon: Icons.home_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.chat,
          unselectedIcon: Icons.chat_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.house,
          unselectedIcon: Icons.house_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.person,
          unselectedIcon: Icons.person_outline,
        ),
      ];
    } else {
      return [
        CrystalNavigationBarItem(
          icon: Icons.home,
          unselectedIcon: Icons.home_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.chat,
          unselectedIcon: Icons.chat_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.house,
          unselectedIcon: Icons.house_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.receipt_long,
          unselectedIcon: Icons.receipt_long_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.folder,
          unselectedIcon: Icons.folder_open_outlined,
        ),
        CrystalNavigationBarItem(
          icon: Icons.person,
          unselectedIcon: Icons.person_outline,
        ),
      ];
    }
  }
}
