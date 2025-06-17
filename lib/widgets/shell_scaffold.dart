import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/theme/theme.dart';
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
        if (currentUser.role == UserRole.landlord) {
          return 'Lakásaim';
        } else if (currentUser.role == UserRole.tenant) {
          return 'Albérletem';
        }
        return '';
      case 2:
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

    // Összeállítjuk a tabokat dinamikusan
    final tabLabels = <String>['Kezdőlap'];
    final tabIcons = <IconData>[FontAwesome.house];

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
          SizedBox(
            height: 80,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/bg1.png', fit: BoxFit.cover),
                Container(color: Colors.black.withOpacity(0.4)),
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
                if (actions != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: MotionTabBar(
        labels: tabLabels,
        initialSelectedTab: tabLabels[index],
        tabIconColor: Colors.grey,
        tabSelectedColor: Colors.blueAccent,
        textStyle: const TextStyle(color: Colors.blueAccent),
        icons: tabIcons,
        tabSize: 50,
        onTabItemSelected: (newIndex) {
          ref.read(bottomNavIndexProvider.notifier).state = newIndex;
          _handleTap(newIndex, currentUser, context);
        },
      ),
    );
  }

  void _handleTap(
      int i,
      UserModel currentUser,
      BuildContext context,
      ) {
    if (i == 0) return context.go('/home');

    if (i == 1) {
      if (currentUser.role == UserRole.landlord) {
        return context.go('/flats');
      } else if (currentUser.role == UserRole.tenant) {
        return context.go('/my-rental');
      }
    }
    if (i == 2 || (i == 1)) return context.go('/profil');
  }
}
