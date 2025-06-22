import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';

class PaymentService {
  final SupabaseClient supabase;

  PaymentService(this.supabase);

  Future<List<Payment>> getPaymentsByInvoiceId(String invoiceId) async {
    final response = await supabase
        .from('payments')
        .select()
        .eq('invoice_id', invoiceId);

    final data = response as List<dynamic>;
    return data.map((e) => Payment.fromMap(e)).toList();
  }

  Future<void> addPayment(Payment payment) async {
    final response = await supabase.from('payments').insert(payment.toMap());

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }
}