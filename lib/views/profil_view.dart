import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/routing/app_router.dart';

import '../models/snackbar_message.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class ProfilView extends ConsumerWidget {
  const ProfilView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final List<_ProfileCardData> items = [
      _ProfileCardData(
        icon: FontAwesome.user,
        title: 'Saját adatok',
        onTap: () {
          // Navigálás vagy modal nyitás
        },
      ),
      _ProfileCardData(
        icon: FontAwesome.gear,
        title: 'Beállítások',
        onTap: () {
          // Navigálás beállításokhoz
        },
      ),
      _ProfileCardData(
        icon: Icons.brightness_6,
        title: 'Téma váltás',
        onTap: () {
          ref.read(themeModeProvider.notifier).state =
              themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        },
      ),
      _ProfileCardData(
        icon: FontAwesome.arrow_right_from_bracket,
        title: 'Kijelentkezés',
        onTap: () async {
          final router = GoRouter.of(context); // ezt tedd ki előre
          try {
            await authService.signOut();
            router.goNamed(
              AppRoute.welcome.name,
              extra: SnackBarMessage(message: 'Sikeres kijelentkezés'),
            );
          } catch (e) {
            router.goNamed(
              AppRoute.welcome.name,
              extra: SnackBarMessage(
                message: 'Hiba a kijelentkezés során: $e',
                isError: true,
              ),
            );
          }
        },
      ),
    ];

    return SafeArea(
      top: false,
      bottom: true,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: double.infinity,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20),
                      const SizedBox(width: 16),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCardData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _ProfileCardData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
