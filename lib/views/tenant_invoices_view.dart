import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/theme_provider.dart';
import '../models/invoice_status.dart';

class TenantInvoicesView extends ConsumerWidget {
  final String tenantUserId;

  const TenantInvoicesView({required this.tenantUserId, super.key});

  Icon statusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.fizetve:
        return const Icon(Icons.check_circle, color: Colors.green);
      case InvoiceStatus.kiallitva:
        return const Icon(Icons.hourglass_bottom, color: Colors.orange);
      case InvoiceStatus.lejart:
        return const Icon(Icons.warning, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(tenantInvoicesProvider(tenantUserId));
    final statusFilter = ref.watch(invoiceStatusFilterProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
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
                  onPressed: () => context.goNamed(AppRoute.alberleteim.name),
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
          // Status szűrő dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: DropdownButton<String?>(
              isExpanded: true,
              value: statusFilter,
              hint: const Text('Számla státusz szűrése'),
              underline: Container(
                height: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Összes')),
                ...InvoiceStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status.name,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(invoiceStatusFilterProvider.notifier).state = value;
              },
            ),
          ),

          // Számlák listája
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const Center(child: Text('Nincs számla'));
                }

                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Card(
                      child: ListTile(
                        leading: statusIcon(invoice.status),
                        title: Text('Számla: ${invoice.id ?? 'N/A'}'),
                        subtitle: Text(
                          'Összeg: ${invoice.totalAmount.toStringAsFixed(2)} Ft\n'
                          'Lejárat: ${invoice.dueDate.toLocal().toString().split(' ')[0] ?? '-'}',
                        ),
                        onTap: () {
                          final result = context.pushNamed(
                            AppRoute.invoiceDetaul.name,
                            pathParameters: {
                              "invoiceId": invoice.id as String,
                            },
                          );
                        },
                      ),
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
                  (error, _) =>
                      Center(child: Text('Hiba történt: ${error.toString()}')),
            ),
          ),
        ],
      ),
    );
  }
}
