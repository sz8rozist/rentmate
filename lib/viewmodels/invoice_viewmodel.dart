import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/models/invoice_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flat_model.dart';
import '../models/invoice_item.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/invoice_service.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final supabase = Supabase.instance.client;
  return InvoiceService(supabase);
});

final landlordInvoicesProvider = FutureProvider.autoDispose
    .family<Map<Flat, List<Invoice>>, String>((ref, landlordUserId) {
      final service = ref.watch(invoiceServiceProvider);
      final statusFilter = ref.watch(invoiceStatusFilterProvider);
      return service.getLandlordInvoices(
        landlordUserId,
        statusFilter: statusFilter,
      );
    });

final invoiceStatusFilterProvider = StateProvider<String?>((ref) => null);

final invoiceByIdProvider = FutureProvider.autoDispose.family<Invoice?, String>(
  (ref, invoiceId) {
    final service = ref.watch(invoiceServiceProvider);
    return service.getInvoiceById(invoiceId);
  },
);

final invoiceEditViewModelProvider = AsyncNotifierProvider.family<
  InvoiceEditViewModel, // osztály
  Invoice, // visszatérési érték
  String // paraméter típusa
>(InvoiceEditViewModel.new);

final tenantInvoicesProvider = FutureProvider.autoDispose
    .family<List<Invoice>, String>((ref, tenantUserId) {
  final service = ref.watch(invoiceServiceProvider);
  final statusFilter = ref.watch(invoiceStatusFilterProvider);
  return service.getTenantInvoices(
    tenantUserId,
    statusFilter: statusFilter,
  );
});

class InvoiceEditViewModel extends FamilyAsyncNotifier<Invoice, String> {
  late final InvoiceService _service;

  @override
  Future<Invoice> build(String invoiceId) async {
    _service = InvoiceService(Supabase.instance.client);
    final invoice = await _service.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw Exception("Számla nem található");
    }
    return invoice;
  }

  void setAmount(String value) {
    final amount = double.tryParse(value) ?? 0;
    state = AsyncData(state.value!.copyWith(totalAmount: amount));
  }

  void updateItem(int index, {String? description, double? amount}) {
    final invoice = state.value!;
    final updatedItems = [...?invoice.items];
    final oldItem = updatedItems[index];
    updatedItems[index] = oldItem.copyWith(
      description: description ?? oldItem.description,
      amount: amount ?? oldItem.amount,
    );
    state = AsyncData(invoice.copyWith(items: updatedItems));
  }

  void addItem({String description = '', double amount = 0}) {
    state = state.whenData((invoice) {
      final updated = [...?invoice.items, InvoiceItem(description: description, amount: amount)];
      return invoice.copyWith(items: updated);
    });
  }

  void removeItem(int index) {
    final invoice = state.value!;
    final updatedItems = [...?invoice.items]..removeAt(index);
    state = AsyncData(invoice.copyWith(items: updatedItems));
  }

  void setDueDate(DateTime date) {
    state = AsyncData(state.value!.copyWith(dueDate: date));
  }

  void setStatus(InvoiceStatus status) {
    state = AsyncData(state.value!.copyWith(status: status));
  }

  void addPayment({double amount = 0, required DateTime date}) {
    state = state.whenData((invoice) {
      final updated = [...?invoice.payments, Payment(amount: amount, paymentDate: date)];
      return invoice.copyWith(payments: updated);
    });
  }


  // Befizetés törlése
  void removePayment(int index) {
    final invoice = state.value!;
    final updatedPayments = [...?invoice.payments]..removeAt(index);
    state = AsyncData(invoice.copyWith(payments: updatedPayments));
  }

  // Befizetés frissítése
  void updatePayment(
    int index, {
    double? amount,
    DateTime? date,
    String? method,
  }) {
    final invoice = state.value!;
    final updatedPayments = [...?invoice.payments];
    final old = updatedPayments[index];
    updatedPayments[index] = old.copyWith(
      amount: amount ?? old.amount,
      paymentDate: date ?? old.paymentDate,
    );
    state = AsyncData(invoice.copyWith(payments: updatedPayments));
  }

  Future<void> save() async {
    final invoice = state.value!;
    await _service.updateInvoice(invoice);
  }
}
