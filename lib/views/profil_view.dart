import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/theme/theme.dart';

// Importáld az AuthService providert
import '../viewmodels/auth_viewmodel.dart';

class ProfilView extends ConsumerWidget {
  const ProfilView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

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
        icon: FontAwesome.arrow_right_from_bracket,
        title: 'Kijelentkezés',
        onTap: () async {
          try {
            await authService.signOut();
            context.goNamed(AppRoute.signin.name);
          } catch (e) {
            // Hibakezelés: pl. SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hiba a kijelentkezés során: $e')),
            );
          }
        },
      ),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20, color: lightColorScheme.secondary),
                      const SizedBox(width: 16),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
