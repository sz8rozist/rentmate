class InvoiceItem {
  final String? id;
  final String? invoiceId;
  final String description;
  final double amount;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.description,
    required this.amount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    id: map['id'],
    invoiceId: map['invoice_id'],
    description: map['description'],
    amount: double.parse(map['amount'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoice_id': invoiceId,
    'description': description,
    'amount': amount,
  };

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? description,
    double? amount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }
}
