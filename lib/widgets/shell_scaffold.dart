import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
import '../models/user_role.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  final List<Widget>? actions;
  const ShellScaffold({super.key, required this.child, this.actions});

  String _getTitle(int index, UserModel currentUser) {
    switch (index) {
      case 0:
        return 'Kezdőlap';
      case 1:
        return 'Chat';
      case 2:
        if (currentUser.role == UserRole.landlord) {
          return 'Lakásaim';
        } else if (currentUser.role == UserRole.tenant) {
          return 'Albérletem';
        }
        return '';
      case 3:
        return 'Profil';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return const SizedBox();
    }
    final title = _getTitle(index, currentUser);

    final tabLabels = <String>['Kezdőlap', 'Chat'];
    final tabIcons = <IconData>[FontAwesome.house, FontAwesome.message];

    if (currentUser.role == UserRole.landlord) {
      tabLabels.add('Lakásaim');
      tabIcons.add(FontAwesome.house_user);
    } else if (currentUser.role == UserRole.tenant) {
      tabLabels.add('Albérletem');
      tabIcons.add(Icons.home_work);
    }

    tabLabels.add('Profil');
    tabIcons.add(FontAwesome.user);

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          Container(
            height: 80 + MediaQuery.of(context).padding.top,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header-image.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bal oldali hárompontos ikon
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return _buildBottomSheetMenu(context, ref);
                        },
                      );
                    },
                  ),

                  // Középen a cím, kitölti a helyet
                  Expanded(
                    child: Text(
                      title,
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

                  SizedBox(
                    width: 48, // vagy annyi, amekkora hely kell az ikonoknak (pl. egy IconButton mérete)
                    child: actions != null
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.background.withOpacity(0.3),
              child: child,
            ),
          ),
        ],
      ),

      bottomNavigationBar: MotionTabBar(
        labels: tabLabels,
        initialSelectedTab: tabLabels[index],
        tabIconColor: Colors.grey,
        tabBarColor: Theme.of(context).colorScheme.background,
        tabSelectedColor: Theme.of(context).colorScheme.primary,
        textStyle: TextStyle(color: Theme.of(context).colorScheme.primary),        icons: tabIcons,
        tabSize: 50,
        onTabItemSelected: (newIndex) {
          ref.read(bottomNavIndexProvider.notifier).state = newIndex;
          _handleTap(newIndex, currentUser, context);
        },
      ),
    );
  }

  Widget _buildBottomSheetMenu(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Opcionalis fejléc
            Text(
              'Menü',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menü elemek
            ListTile(
              leading: const Icon(Icons.payments, color: Colors.blueAccent),
              title: const Text(
                'Számlák',
                style: TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                context.goNamed(AppRoute.invoices.name);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.blueAccent.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Kijelentkezés',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
              onTap: () async {
                Navigator.pop(context);
                final authService = ref.read(authServiceProvider);
                try {
                  await authService.signOut();
                  context.goNamed('welcome');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hiba a kijelentkezés során: $e'),
                    ),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  void _handleTap(int i, UserModel currentUser, BuildContext context) {
    if (i == 0) return context.goNamed(AppRoute.home.name);
    if(i == 1) return context.goNamed(AppRoute.chat.name);

    if (i == 2) {
      if (currentUser.role == UserRole.landlord) {
        return context.goNamed(AppRoute.lakasaim.name);
      } else if (currentUser.role == UserRole.tenant) {
        return context.goNamed(AppRoute.alberleteim.name);
      }
    }
    if (i == 3) return context.goNamed(AppRoute.profile.name);
  }
}
