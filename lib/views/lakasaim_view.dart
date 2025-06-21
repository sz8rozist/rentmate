import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../models/flat_model.dart';
import '../viewmodels/flat_list_provider.dart';
import 'package:icons_plus/icons_plus.dart';

class LakasaimView extends ConsumerWidget {
  const LakasaimView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flatList = ref.watch(flatListProvider);
    return flatList.when(
      loading: () => SizedBox.expand(
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Platform.isIOS
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
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return Slidable(
                key: ValueKey(flat.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  dismissible: DismissiblePane(
                    onDismissed: () async {
                      final result = await showOkCancelAlertDialog(
                        context: context,
                        title: 'Biztosan törlöd?',
                        okLabel: 'Igen',
                        cancelLabel: 'Mégse',
                        isDestructiveAction: true,
                      );

                      if (result == OkCancelResult.ok) {
                        await ref.read(flatListProvider.notifier).removeFlat(flat);
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar.success('${flat.address} törölve lett.'),
                        );
                      } else {
                        // ha mégsem törlöd, visszarakjuk az elemet a listába
                        ref.read(flatListProvider.notifier).refresh();
                      }
                    },
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Törlés',
                    ),
                  ],
                ),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                FontAwesome.house_chimney,
                size: 36,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  flat.address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ],
          ),
        ),
      ),
    );
  }
}
