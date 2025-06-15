import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../models/flat_model.dart';
import '../viewmodels/flat_list_provider.dart';

class LakasaimView extends ConsumerWidget {
  const LakasaimView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flatList = ref.watch(flatListProvider);
    return flatList.when(
      loading:
          () => SizedBox.expand(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child:
                    Platform.isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
              ),
            ),
          ),
      error: (e, _) => Center(child: Text('Hiba történt: $e')),
      data: (flats) {
        if (flats.isEmpty) {
          return const Center(child: Text('Nincsenek lakások.'));
        }

        return SafeArea(
          bottom: true,
          top: false,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return Dismissible(
                key: ValueKey(flat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  bool? result = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Biztosan törlöd?'),
                          actions: [
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              label: const Text('Mégse'),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(true),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Igen'),
                            ),
                          ],
                        ),
                  );

                  return result == true;
                },
                onDismissed: (_) async {
                  await ref.read(flatListProvider.notifier).removeFlat(flat);
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar.success('${flat.address} törölve lett.'),
                  );
                },
                child: FlatCard(flat: flat),
              );
            },
          ),
        );
      },
    );
  }
}

class FlatCard extends StatelessWidget {
  final Flat flat;

  const FlatCard({super.key, required this.flat});

  Color _getStatusColor(FlatStatus status) {
    switch (status.value) {
      case 'szabad':
        return Colors.green.shade100;
      case 'kiadva':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getStatusTextColor(FlatStatus status) {
    switch (status.value) {
      case 'szabad':
        return Colors.green.shade800;
      case 'kiadva':
        return Colors.red.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.pushNamed(
          AppRoute.flatDetail.name,
          pathParameters: {'id': flat.id as String},
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    flat.images.first.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flat.address,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(flat.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      flat.status.label,
                      style: TextStyle(
                        color: _getStatusTextColor(flat.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bérlő: ${flat.landLord}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
