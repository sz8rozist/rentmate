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
      MenuItem('Tranzakciók', Icons.receipt_long, AppRoute.invoices),
      MenuItem('Kaució kezelése', Icons.receipt_long, AppRoute.invoices),
      MenuItem(
        'Javítási/Karbantartási költségek kezelése',
        Icons.receipt_long,
        AppRoute.invoices,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menü',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                // kisebb távolság
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                // kisebb kártya, majdnem négyzet
                children: [
                  ...standaloneMenus.map((item) => MenuCard(item: item)),
                ],
              ),
            ),
          ],
        ),
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
    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // kicsit kisebb lekerekítés
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // kicsit kevesebb padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                item.icon,
                size: 30, // kisebb ikon
                color: Colors.grey[800], // sötétszürke ikon
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14, // kisebb szöveg
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // enyhén szürke szöveg
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
