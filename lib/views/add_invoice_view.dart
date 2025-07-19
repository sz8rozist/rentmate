import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rentmate/models/invoice_item.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:rentmate/widgets/custom_text_form_field.dart';
import 'package:rentmate/widgets/loading_overlay.dart';
import '../models/invoice_model.dart';
import '../models/invoice_status.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/theme_provider.dart';
import 'package:uuid/uuid.dart';

class AddInvoiceScreen extends ConsumerStatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  ConsumerState<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends ConsumerState<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final TextEditingController _monthController = TextEditingController(
    text: DateTime.now().month.toString(),
  );

  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  InvoiceStatus _selectedStatus = InvoiceStatus.kiallitva;

  final List<InvoiceItem> _items = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final initialDate = isIssueDate ? _issueDate : _dueDate;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = newDate;
        } else {
          _dueDate = newDate;
        }
      });
    }
  }

  void _showAddItemDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Új számla tétel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextFormField(
                controller: descriptionController,
                labelText: "Megnevezés",
                validator:
                    RequiredValidator(
                      errorText: 'Kérlek add meg a megnevezést',
                    ).call,
              ),

              const SizedBox(height: 16),

              CustomTextFormField(
                controller: amountController,
                labelText: "Összeg",
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator:
                    MultiValidator([
                      RequiredValidator(errorText: 'Kötelező mező'),
                      PatternValidator(
                        r'^\d+(\.\d+)?$',
                        errorText: 'Érvénytelen számformátum',
                      ),
                    ]).call,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Mégse'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Mentés'),
              onPressed: () {
                final description = descriptionController.text.trim();
                final amount = amountController.text.trim();

                if (description.isEmpty) {
                  // Egyszerű validáció, akár form is lehetne
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kérlek add meg a megnevezést')),
                  );
                  return;
                }
                if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(amount)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Érvénytelen számformátum')),
                  );
                  return;
                }

                setState(() {
                  final newItem = InvoiceItem(
                    description: descriptionController.text,
                    amount: double.parse(amountController.text),
                  );
                  _items.add(newItem);
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveInvoice(String flatId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      CustomSnackBar.error(context, "Legalább egy számla tétel szükséges");
      return;
    }
    if (_items.any((item) => item.description.isEmpty || item.amount <= 0)) {
      CustomSnackBar.error(context, "Kérlek töltsd ki az összes tétel adatot");
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Összeg kiszámítása
      final totalAmount = _items.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      var uuid = Uuid();
      // Invoice objektum létrehozása
      final invoice = Invoice(
        id: uuid.v4(),
        flatId: flatId,
        year: int.parse(_yearController.text),
        month: int.parse(_monthController.text),
        issueDate: _issueDate,
        dueDate: _dueDate,
        totalAmount: totalAmount,
        status: _selectedStatus,
      );

      // Invoice mentése a tételekkel együtt
      final service = ref.read(invoiceServiceProvider);
      await service.addInvoiceWithItems(invoice, _items);

      // Ha siker, visszalépés és jelezd, hogy frissítsék a listát
      context.goNamed(AppRoute.home.name);
      CustomSnackBar.success(context,"Sikeres számla feltöltés.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
        print('Hiba: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
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
                    'Új számla létrehozása',
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
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Év és hónap
                CustomTextFormField(
                  controller: _yearController,
                  labelText: "Év",
                  keyboardType: TextInputType.number,
                  validator:
                      MultiValidator([
                        RequiredValidator(errorText: 'Kötelező mező'),
                        PatternValidator(
                          r'^\d{4}$',
                          errorText: 'Érvénytelen év formátum',
                        ),
                      ]).call,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _monthController,
                  labelText: "Hónap",
                  keyboardType: TextInputType.number,
                  validator:
                      MultiValidator([
                        RequiredValidator(errorText: 'Kötelező mező'),
                        PatternValidator(
                          r'^\d{1,2}$',
                          errorText: 'Érvénytelen hónap formátum',
                        ),
                        PatternValidator(
                          r'^(0?[1-9]|1[0-2])$',
                          errorText: 'Érvénytelen hónap (1-12)',
                        ),
                      ]).call,
                ),
                const SizedBox(height: 16),
                // Kiállítási dátum picker
                ListTile(
                  title: const Text('Kiállítási dátum'),
                  subtitle: Text(dateFormat.format(_issueDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),

                // Fizetési határidő picker
                ListTile(
                  title: const Text('Fizetési határidő'),
                  subtitle: Text(dateFormat.format(_dueDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),

                const SizedBox(height: 16),

                // Státusz dropdown
                DropdownButtonFormField<InvoiceStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Státusz'),
                  items:
                      InvoiceStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                    }
                  },
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Számla tételek',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty) Text('Nincsenek tételek.'),
                    ..._items.map((item) {
                      return Dismissible(
                        key: ValueKey(item),
                        // vagy item.id, ha van egyedi azonosító
                        direction: DismissDirection.endToStart,
                        // jobbról balra húzás
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Itt jön a törlés megerősítés dialógus
                          final bool? result = await showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Tétel törlése'),
                                  content: Text(
                                    'Biztosan törlöd a(z) "${item.description}" tételt?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(false),
                                      child: const Text('Mégse'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(true),
                                      child: const Text('Törlés'),
                                    ),
                                  ],
                                ),
                          );
                          return result ?? false;
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _items.remove(item);
                          });
                          CustomSnackBar.success(
                            context,'A(z) ${item.description} tétel törölve lett',
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              item.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text('${item.amount.toInt()} Ft'),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                TextButton.icon(
                  onPressed: () => _showAddItemDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tétel hozzáadása'),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    final flat = ref.read(selectedFlatProvider);
                    if (flat != null && flat.id != null) {
                      _saveInvoice(flat.id!);
                    }
                  },
                  child: const Text('Mentés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
