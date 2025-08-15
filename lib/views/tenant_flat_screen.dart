import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/tenant_flat_viewmodel.dart';
import '../widgets/swipe_image_galery.dart';

class TenantFlatScreen extends ConsumerWidget {
  const TenantFlatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flatAsync = ref.watch(tenantFlatViewModelProvider);

    return Scaffold(
      body: flatAsync.when(
        loading: () => Center(child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Text('Hiba történt az albérlet megjelenítése közben.'),
        ),
        data: (flat) {
          if (flat == null) {
            return const Center(
              child: Text('Jelenleg nincs aktív albérleted.'),
            );
          }

          final imageProviders =
          flat.images
              ?.map((img) => NetworkImage(img.url) as ImageProvider)
              .toList();

          return SafeArea(
            bottom: true,
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cím
                        Text(
                          flat.address,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),

                        const SizedBox(height: 16),

                        // Képgaléria
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: flat.images!.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final img = flat.images![index];
                              return GestureDetector(
                                onTap: () {
                                  showSwipeImageGallery(
                                    context,
                                    children: imageProviders!,
                                    initialIndex: index,
                                    swipeDismissible: true,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    img.url,
                                    width: 300,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Szekció: Albérlet adatok
                        SectionCard(
                          title: 'Albérlet adatok',
                          children: [
                            InfoRow(
                              label: 'Bérleti díj',
                              value: '${flat.price} Ft / hó',
                            ),
                            InfoRow(label: 'Státusz', value: flat.status.label),
                          ],
                        ),

                        // Szekció: Főbérlő
                        SectionCard(
                          title: 'Főbérlő',
                          children: [InfoRow(label: 'Név', value: "Ismeretlen")],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Itt a gomb fixen lent
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 35),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Kilépési szándék'),
                            content: const Text(
                              'Biztosan jelzed a kilépési szándékodat?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('Mégse'),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final vm = ref.read(
                                    tenantFlatViewModelProvider.notifier,
                                  );
                                  return ElevatedButton(
                                    onPressed: () async {
                                      context.pop();
                                      // await vm.sendExitRequest();
                                      CustomSnackBar.success(context,"Kilépési szándék jelzése elküldve");
                                    },
                                    child: const Text('Igen, jelzem'),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Kilépési szándék jelzése'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Egy kártyaszerű szekció több információs sorral
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Egy sor címke + érték kombinációval
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
