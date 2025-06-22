import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/flat_model.dart';
import '../models/invoice_item.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

class InvoiceService {
  final SupabaseClient supabase;

  InvoiceService(this.supabase);

  Future<Map<Flat, List<Invoice>>> getLandlordInvoices(
    String landlordUserId, {
    String? statusFilter,
  }) async {
    // Lekérjük az összes flatet ami a landlordhoz tartozik
    final flatResponse = await supabase
        .from('flats')
        .select('*')
        .eq('landlord_user_id', landlordUserId);

    final flatList =
        (flatResponse as List).map((f) => Flat.fromJson(f)).toList();

    // Egy map-be csoportosítjuk: Flat -> Invoices
    Map<Flat, List<Invoice>> result = {};

    for (var flat in flatList) {
      var query = supabase
          .from('invoices')
          .select('*')
          .eq('flat_id', flat.id as String);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      final invoiceResponse = await query
          .order('year', ascending: false)
          .order('month', ascending: false);

      final invoices =
          (invoiceResponse as List).map((i) => Invoice.fromMap(i)).toList();
      result[flat] = invoices;
    }

    return result;
  }

  Future<Invoice?> getInvoiceById(String invoiceId) async {
    // Számla lekérése
    final invoiceResponse =
        await supabase.from('invoices').select().eq('id', invoiceId).single();

    final invoiceData = invoiceResponse;

    // Számla tételek lekérése
    final itemsResponse = await supabase
        .from('invoice_items')
        .select()
        .eq('invoice_id', invoiceId);

    final itemsData = itemsResponse as List<dynamic>;
    final items = itemsData.map((e) => InvoiceItem.fromMap(e)).toList();

    // Befizetések lekérése
    final paymentsResponse = await supabase
        .from('payments')
        .select()
        .eq('invoice_id', invoiceId);

    final paymentsData = paymentsResponse as List<dynamic>;
    final payments = paymentsData.map((e) => Payment.fromMap(e)).toList();

    // Invoice példány létrehozása a tételekkel és befizetésekkel
    return Invoice.createFromMap(invoiceData, items: items, payments: payments);
  }

  Future<void> addInvoiceWithItems(
    Invoice invoice,
    List<InvoiceItem> items,
  ) async {
    await supabase.from('invoices').insert(invoice.toMap());
    final invoiceItemUid = Uuid();
    // Most az összes tételt be kell illeszteni az invoice_items táblába
    final itemsToInsert =
        items.map((item) {
          final map = item.toMap();
          map['id'] = invoiceItemUid.v4();
          map['invoice_id'] = invoice.id; // kapcsoljuk a tételt az invoice-hoz
          return map;
        }).toList();
    await supabase.from('invoice_items').insert(itemsToInsert);
  }
}
