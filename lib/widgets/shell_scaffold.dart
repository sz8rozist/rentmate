import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/viewmodels/theme_provider.dart';
import '../models/user_role.dart';
import '../viewmodels/apartman_provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final List<Widget>? actions;

  const ShellScaffold({super.key, required this.child, this.actions});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final userId = ref.read(authViewModelProvider)
          .asData?.value.payload?.userId;

      if (userId != null) {
        ref.read(apartmentProvider.notifier).loadFlats(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;
    final role = payload?.role;

    final apartmentState = ref.watch(apartmentProvider);

    if (apartmentState.isLoading) {
      return const CircularProgressIndicator();
    }

    if (apartmentState.error != null) {
      return Text(apartmentState.error!);
    }

    final location = GoRouterState.of(context).uri.path;

    if (role == null) {
      return const SizedBox();
    }

    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(context, ref),
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
      bottomNavigationBar: _buildBottomNav(context, location, isDarkMode, role)

    );
  }

  void _showApartmentSheet(BuildContext context, WidgetRef ref) {
    final apartments = ref.read(apartmentProvider).apartments;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: apartments.length,
          itemBuilder: (_, index) {
            final apt = apartments[index];

            return ListTile(
              title: Text(apt.address ?? ''),
              onTap: () {
                ref.read(apartmentProvider.notifier).setActive(apt);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final apartmentState = ref.watch(apartmentProvider);
    final active = apartmentState.active;

    return AppBar(
      title: GestureDetector(
        onTap: () => _showApartmentSheet(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktív lakás'),
            Row(
              children: [
                Text(active?.address ?? 'Válassz lakást'),
                const Icon(Icons.expand_more),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav(ctx, location, isDarkMode, role) {
    final tabs = ['/dashboard', '/tenants', '/finances'];
    final idx = tabs.indexWhere((t) => location.startsWith(t));

    return BottomNavigationBar(
      currentIndex: idx < 0 ? 0 : idx,
      onTap: (i) => context.go(tabs[i]),
      backgroundColor: isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white,
      type: BottomNavigationBarType.fixed, // fix szélesség az ikonoknak
      selectedItemColor: Theme.of(context).colorScheme.primary,
      showUnselectedLabels: true,
      items: _buildBottomNavItems(role),
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
        const BottomNavigationBarItem(icon: Icon(Icons.house), label: 'Albérletem')
      ];
    }
  }
}
