import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';

class LandlordHomeView extends ConsumerStatefulWidget {
  const LandlordHomeView({super.key});

  @override
  ConsumerState<LandlordHomeView> createState() => _LandlordHomeViewState();
}

class _LandlordHomeViewState extends ConsumerState<LandlordHomeView> {
  late final List<MenuItem> standaloneMenus;
  late final Map<String, List<MenuItem>> menuGroups;

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.watch(selectedFlatProvider);

    if (selectedFlat == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakás")),
      );
    }

    standaloneMenus = [
      MenuItem('Lakás kiválasztása', Icons.home, AppRoute.flatSelect),
      MenuItem('Lakás hozzáadása', Icons.add_home, AppRoute.createFlat),
    ];

    menuGroups = {
      'Dokumentumok': [
        MenuItem(
          'Szerződés készítés',
          Icons.description,
          AppRoute.createBerletiSzerzodes,
        ),
        MenuItem(
          'Dokumentum feltöltés',
          Icons.upload_file,
          AppRoute.uploadDocument,
        ),
        MenuItem(
          'Dokumentumok megtekintése',
          Icons.folder_open,
          AppRoute.documents,
          paramName: 'flatId',
          paramValue: selectedFlat.id.toString(),
        ),
      ],
      'Pénzügyek': [
        MenuItem(
          'Tranzakciók',
          Icons.receipt_long,
          AppRoute.invoices,
        ),
        MenuItem(
          'Kaució kezelése',
          Icons.receipt_long,
          AppRoute.invoices,
        ),
        MenuItem(
          'Javítási/Karbantartási költségek kezelése',
          Icons.receipt_long,
          AppRoute.invoices,
        ),
      ],
    };

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Különálló menük
          ...standaloneMenus.map((item) => MenuCard(item: item)),
          const SizedBox(height: 24),

          // Csoportosított menük
          ...menuGroups.entries.map((entry) {
            final groupName = entry.key;
            final menuItems = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...menuItems.map((item) => MenuCard(item: item)),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final AppRoute routeName;
  final String? paramName;
  final String? paramValue;

  MenuItem(
      this.title,
      this.icon,
      this.routeName, {
        this.paramName,
        this.paramValue,
      });
}

class MenuCard extends StatelessWidget {
  final MenuItem item;

  const MenuCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
        title: Text(item.title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (item.paramName != null && item.paramValue != null) {
            context.goNamed(
              item.routeName.name,
              pathParameters: {item.paramName!: item.paramValue!},
            );
          } else {
            context.goNamed(item.routeName.name);
          }
        },
      ),
    );
  }
}
