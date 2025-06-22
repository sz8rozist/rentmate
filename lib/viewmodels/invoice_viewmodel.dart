import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flat_model.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final supabase = Supabase.instance.client;
  return InvoiceService(supabase);
});

final landlordInvoicesProvider =
    FutureProvider.family<Map<Flat, List<Invoice>>, String>((
      ref,
      landlordUserId,
    ) {
      final service = ref.watch(invoiceServiceProvider);
      final statusFilter = ref.watch(invoiceStatusFilterProvider);
      return service.getLandlordInvoices(
        landlordUserId,
        statusFilter: statusFilter,
      );
    });

final invoiceStatusFilterProvider = StateProvider<String?>((ref) => null);

final invoiceByIdProvider = FutureProvider.family<Invoice?, String>((ref, invoiceId) {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoiceById(invoiceId);
});
