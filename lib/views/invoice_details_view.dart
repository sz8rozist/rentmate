import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import '../models/invoice_status.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class InvoiceDetailsScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({required this.invoiceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final invoiceAsyncValue = ref.watch(invoiceByIdProvider(invoiceId));

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
                    'Számla részletek',
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
              Positioned(
                right: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed:
                      () => context.goNamed(
                        AppRoute.editInvoice.name,
                        pathParameters: {"invoiceId": invoiceId},
                      ),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: invoiceAsyncValue.when(
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Számla nem található.'));
          }

          double remainingAmount = invoice.totalAmount;
          final List<TimelineEvent> timelineEvents = [
            TimelineEvent(
              title: 'Számla kiállítva',
              date: invoice.issueDate,
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
            if (invoice.dueDate != null)
              TimelineEvent(
                title: 'Fizetési határidő',
                date: invoice.dueDate,
                icon: Icons.event,
                color: Colors.orange,
              ),
          ];

          final paymentsSorted =
              invoice.payments?.toList()
                ?..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

          for (var payment in paymentsSorted!) {
            remainingAmount -= payment.amount;

            timelineEvents.add(
              TimelineEvent(
                title:
                    'Befizetés: ${payment.amount.toInt()} Ft, Hátralék: ${remainingAmount.toInt()} Ft',
                date: payment.paymentDate,
                icon: Icons.check_circle,
                color: remainingAmount > 0 ? Colors.red : Colors.green,
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Számla adatokat tartalmazó kártya
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Számla azonosító: #${invoice.id}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.date_range),
                              const SizedBox(width: 8),
                              Text(
                                'Dátum: ${_formatDate(invoice.issueDate)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on),
                              const SizedBox(width: 8),
                              Text(
                                'Összeg: ${invoice.totalAmount.toInt()} Ft',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: InvoiceStatusExtension.getColor(
                                    invoice.status.value,
                                  ).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (invoice.items != null && invoice.items!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tételek',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoice.items!.length,
                      itemBuilder: (context, index) {
                        final item = invoice.items![index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(item.description),
                            trailing: Text(
                              '${item.amount.toStringAsFixed(0)} Ft',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
            
                  // Timeline fejléc
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Események',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
            
                  const SizedBox(height: 12),
            
                  // Itt jön a lista, Expanded-ben, hogy kitöltse a maradék helyet és scrollozható legyen
                  Column(
                    children: List.generate(timelineEvents.length, (index) {
                      final event = timelineEvents[index];
                      final isLast = index == timelineEvents.length - 1;
                      return TimelineTile(event: event, isLast: isLast);
                    }),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hiba történt: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class TimelineEvent {
  final String title;
  final DateTime date;
  final IconData icon;
  final Color color;

  TimelineEvent({
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const TimelineTile({required this.event, required this.isLast, super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 50,
            child: Column(
              children: [
                Icon(event.icon, color: event.color, size: 30),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      color: event.color.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(event.date),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
