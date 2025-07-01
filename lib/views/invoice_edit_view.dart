import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/invoice_viewmodel.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';

import '../models/invoice_status.dart';
import '../viewmodels/theme_provider.dart';

class InvoiceEditView extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceEditView({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceEditView> createState() => _InvoiceEditViewState();
}

class _InvoiceEditViewState extends ConsumerState<InvoiceEditView> with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _animationController,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final invoiceId = widget.invoiceId;
    final viewModel = ref.watch(invoiceEditViewModelProvider(invoiceId));
    final fabTheme = Theme.of(context).floatingActionButtonTheme;

    Future<List<String>?> showCustomInputDialog(BuildContext context) async {
      final descriptionController = TextEditingController();
      final amountController = TextEditingController();

      return showDialog<List<String>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Új tétel'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(hintText: 'Leírás'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: 'Összeg'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Mégse'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, [
                    descriptionController.text,
                    amountController.text,
                  ]);
                },
                child: Text('Hozzáadás'),
              ),
            ],
          );
        },
      );
    }

    Future<List<dynamic>?> showPaymentInputDialog(BuildContext context) async {
      final amountController = TextEditingController();
      DateTime? selectedDate;

      return showDialog<List<dynamic>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Új befizetés'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: 'Összeg'),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Dátum kiválasztása',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate == null
                              ? 'Válassz dátumot'
                              : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Mégse'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDate != null) {
                        Navigator.pop(context, [
                          amountController.text,
                          selectedDate,
                        ]);
                      } else {
                        // Ha nincs kiválasztva dátum, nem engedjük tovább
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Kérlek, válassz dátumot!')),
                        );
                      }
                    },
                    child: Text('Hozzáadás'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

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
                    'Számla szerkesztése',
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
                  onPressed:
                      () => context.goNamed(
                        AppRoute.invoiceDetaul.name,
                        pathParameters: {"invoiceId": invoiceId},
                      ),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
              Positioned(
                right: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: () async {
                    await ref
                        .read(invoiceEditViewModelProvider(invoiceId).notifier)
                        .save();
                    if (context.mounted) {
                      context.goNamed(
                        AppRoute.invoiceDetaul.name,
                        pathParameters: {"invoiceId": invoiceId},
                      );
                    }
                  },
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: viewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hiba történt: $error')),
        data: (invoice) {
          final items = invoice.items ?? [];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                CustomTextFormField(
                  initialValue: invoice.totalAmount.toStringAsFixed(0),
                  labelText: "Összeg",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    ref
                        .read(invoiceEditViewModelProvider(invoiceId).notifier)
                        .setAmount(value);
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<InvoiceStatus>(
                  value: invoice.status,
                  decoration: const InputDecoration(labelText: 'Státusz'),
                  items:
                      InvoiceStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(
                            invoiceEditViewModelProvider(invoiceId).notifier,
                          )
                          .setStatus(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tételek:',
                ),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Slidable(
                      key: ValueKey(item),  // egyedi key a slidable-nak
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              ref
                                  .read(
                                invoiceEditViewModelProvider(invoiceId).notifier,
                              )
                                  .removeItem(index);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Törlés',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(item.description),
                          trailing: Text(
                            item.amount.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                // Itt hasonlóan hozzáadhatsz fizetéseket, ha szeretnéd:
                const Text(
                  'Befizetések:',
                ),
                ...(invoice.payments ?? []).asMap().entries.map((entry) {
                  final payment = entry.value;
                  final index = entry.key;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Slidable(
                      key: ValueKey(payment),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              ref
                                  .read(
                                invoiceEditViewModelProvider(invoiceId).notifier,
                              )
                                  .removePayment(index);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Törlés',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(payment.amount.toStringAsFixed(0)),
                          trailing: Text(
                            payment.paymentDate.toIso8601String().split('T').first,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionBubble(
        items: <Bubble>[
          Bubble(
            title: "Tétel hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Theme.of(context).primaryColor,
            icon: Icons.add_shopping_cart,
            titleStyle: const TextStyle(color: Colors.white),
              onPress: () async {
                final result = await showCustomInputDialog(context);

                if (result != null && result.length == 2) {
                  ref.read(invoiceEditViewModelProvider(invoiceId).notifier).addItem(
                    description: result[0],
                    amount: double.tryParse(result[1]) ?? 0,
                  );
                }
                _animationController.reverse();
              }
          ),
          Bubble(
            title: "Befizetés hozzáadása",
            iconColor: Colors.white,
            bubbleColor: Theme.of(context).primaryColor,
            icon: Icons.payment,
            titleStyle: const TextStyle(color: Colors.white),
              onPress: () async {
                final result = await showPaymentInputDialog(context);

                if (result != null && result.length == 2) {
                  final amount = double.tryParse(result[0]) ?? 0;
                  final date = result[1] as DateTime;
                  ref.read(invoiceEditViewModelProvider(invoiceId).notifier).addPayment(
                    amount: amount,
                    date: date,
                  );
                }
                _animationController.reverse();
              }
          ),
        ],
        animation: _animation,
        onPress: () => _animationController.isCompleted
            ? _animationController.reverse()
            : _animationController.forward(),
        iconColor: fabTheme.foregroundColor ?? Colors.white,
        animatedIconData: AnimatedIcons.menu_close,
        backGroundColor: fabTheme.backgroundColor ?? Colors.white,
      ),
    );
  }
}
