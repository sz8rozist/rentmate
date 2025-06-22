import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invoice_item.dart';

class InvoiceItemService {
  final SupabaseClient supabase;

  InvoiceItemService(this.supabase);

  Future<List<InvoiceItem>> getItemsByInvoiceId(String invoiceId) async {
    final response = await supabase
        .from('invoice_items')
        .select()
        .eq('invoice_id', invoiceId);

    final data = response as List<dynamic>;
    return data.map((e) => InvoiceItem.fromMap(e)).toList();
  }

  Future<void> addInvoiceItem(InvoiceItem item) async {
    final response = await supabase.from('invoice_items').insert(item.toMap());

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<void> updateInvoiceItem(InvoiceItem item) async {
    final response = await supabase
        .from('invoice_items')
        .update(item.toMap())
        .eq('id', item.id as String);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }
}