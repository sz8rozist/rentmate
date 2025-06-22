
class Payment {
  final String id;
  final String invoiceId;
  final DateTime paymentDate;
  final double amount;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.paymentDate,
    required this.amount,
  });

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    invoiceId: map['invoice_id'],
    paymentDate: DateTime.parse(map['payment_date']),
    amount: double.parse(map['amount'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoice_id': invoiceId,
    'payment_date': paymentDate.toIso8601String(),
    'amount': amount,
  };
}
