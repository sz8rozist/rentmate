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
  int _getIndexFromRoute(String location, UserModel user) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chatMessage')) return 1;

    if (user.role == UserRole.landlord && location.startsWith('/flat')) return 2;
    if (user.role == UserRole.tenant && location.startsWith('/my-rental')) return 2;

    if (location.startsWith('/profil')) return 3;

    return 0; // default fallback
  }
  String _getTitle(int index, UserModel currentUser) {
    switch (index) {
      case 0:
        return 'Kezdőlap';
      case 1:
        return 'Chat';
      case 2:
        if (currentUser.role == UserRole.landlord) {
          return 'Lakásom';
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
    final currentUser = ref.watch(currentUserProvider).value;
    late String? flatId;
    if (currentUser == null) {
      return const SizedBox();
    }

    if(currentUser.flatId != null){
      flatId = currentUser.flatId;
    }

    final location = GoRouterState.of(context).matchedLocation;
    final index = _getIndexFromRoute(location, currentUser);
    print(index);
    final title = _getTitle(index, currentUser);

    final tabLabels = <String>['Kezdőlap', 'Chat'];
    final tabIcons = <IconData>[FontAwesome.house, FontAwesome.message];

    if (currentUser.role == UserRole.landlord) {
      tabLabels.add('Lakásom');
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
                          return _buildBottomSheetMenu(context, ref, currentUser);
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
          print(newIndex);
          ref.read(bottomNavIndexProvider.notifier).state = newIndex;
          _handleTap(newIndex, currentUser, context);
        },
      ),
    );
  }

  Widget _buildBottomSheetMenu(BuildContext context, WidgetRef ref, UserModel currentUserModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
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
              // LANDLORD esetén külön szekciók
              if (currentUserModel.role == UserRole.landlord) ...[
                // Számlák szekció
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Számlák',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.payments, color: Colors.blueAccent),
                  title: const Text('Számlák listája', style: TextStyle(fontSize: 16)),
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
                  leading: const Icon(Icons.payment, color: Colors.blueAccent),
                  title: const Text('Számla készítés', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(AppRoute.newInvoice.name);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),                const SizedBox(height: 24),

                // Dokumentumok szekció
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dokumentumok',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blueAccent),
                  title: const Text('Dokumentumok', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(AppRoute.documents.name, pathParameters: {"flatId": currentUserModel.flatId ?? ""});
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blueAccent),
                  title: const Text('Dokumentum feltöltés', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(AppRoute.uploadDocument.name);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blueAccent),
                  title: const Text('Bérleti szerződés készítés', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(AppRoute.createBerletiSzerzodes.name);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Ha tenant vagy más szerep, akkor itt lehet más menü, pl. a régi "Számlák" és "Dokumentumok" egyszerű verziója
                ListTile(
                  leading: const Icon(Icons.payments, color: Colors.blueAccent),
                  title: const Text('Számlák', style: TextStyle(fontSize: 18)),
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
                  leading: const Icon(Icons.folder, color: Colors.blueAccent),
                  title: const Text('Dokumentumok', style: TextStyle(fontSize: 18)),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed(AppRoute.documents.name, pathParameters: {"flatId": currentUserModel.flatId ?? ""});
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 24),
              ],
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
      ),
    );
  }


  void _handleTap(int i, UserModel currentUser, BuildContext context) {
    if (i == 0) return context.goNamed(AppRoute.home.name);
    if(i == 1) return context.goNamed(AppRoute.chatMessage.name);

    if (i == 2) {
      if (currentUser.role == UserRole.landlord) {
        return context.goNamed(AppRoute.lakasom.name);
      } else if (currentUser.role == UserRole.tenant) {
        return context.goNamed(AppRoute.alberleteim.name);
      }
    }
    if (i == 3) return context.goNamed(AppRoute.profile.name);
  }
}
