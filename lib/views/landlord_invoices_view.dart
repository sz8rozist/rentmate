import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/models/invoice_status.dart';
import '../routing/app_router.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class LandlordInvoicesScreen extends ConsumerWidget {
  final String landlordUserId;

  const LandlordInvoicesScreen({required this.landlordUserId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedStatus = ref.watch(invoiceStatusFilterProvider);
    final invoicesAsync = ref.watch(landlordInvoicesProvider(landlordUserId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          // A háttér lefedi a státusz sávot is
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/header-image.png', fit: BoxFit.cover),
              Container(
                color:
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
              ),
              // A tartalmat beljebb húzzuk, hogy ne lógjon be a status bar területére
              Padding(
                padding: EdgeInsets.fromLTRB(
                  60,
                  MediaQuery.of(context).padding.top,
                  16,
                  0,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Számlák',
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
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.goNamed(AppRoute.home.name),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Szűrő rész
          Container(
            color: colorScheme.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Szűrő státuszra:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    value: selectedStatus,
                    isExpanded: true,
                    underline: Container(height: 2, color: colorScheme.primary),
                    hint: const Text('Összes'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Összes'),
                      ),
                      ...InvoiceStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status.name,
                          child: Text(status.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(invoiceStatusFilterProvider.notifier).state =
                          value;
                    },
                  ),
                ),
              ],
            ),
          ),
          // A lista
          Expanded(
            child: SafeArea(
              child: invoicesAsync.when(
                data: (data) {
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        'Nincs számla.',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: data.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          color: colorScheme.outline,
                          height: 32,
                          thickness: 1,
                        ),
                    itemBuilder: (context, index) {
                      final flat = data.entries.elementAt(index).key;
                      final invoices = data.entries.elementAt(index).value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flat.address,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (invoices.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16,
                              ),
                              child: Text(
                                'Nincsenek számlák ehhez a lakáshoz.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            )
                          else
                            ...invoices.map((invoice) {
                              final statusColor =
                                  InvoiceStatusExtension.getColor(
                                    invoice.status.value,
                                  );
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                   context.pushNamed(
                                    AppRoute.invoiceDetaul.name,
                                    pathParameters: {
                                      "invoiceId": invoice.id as String,
                                    },
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withOpacity(0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${invoice.year}.${invoice.month.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Összeg: ${invoice.totalAmount.toInt()} Ft',
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          InvoiceStatusExtension.getLabel(
                                            invoice.status.value,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  );
                },
                loading:
                    () => Center(
                      child:
                          Platform.isIOS
                              ? const CupertinoActivityIndicator()
                              : const CircularProgressIndicator(),
                    ),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Hiba történt: $e',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
