import 'package:rentmate/models/invoice_status.dart';
import 'package:rentmate/models/payment_model.dart';

import 'invoice_item.dart';

class Invoice {
  final String? id;
  final String flatId;
  final int year;
  final int month;
  final DateTime issueDate;
  final DateTime dueDate;
  final double totalAmount;
  final InvoiceStatus status;
  final List<InvoiceItem>? items;
  final List<Payment>? payments;

  Invoice({
    this.id,
    required this.flatId,
    required this.year,
    required this.month,
    required this.issueDate,
    required this.dueDate,
    required this.totalAmount,
    required this.status,
    this.items,
    this.payments,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
    id: map['id'],
    flatId: map['flat_id'],
    year: map['year'],
    month: map['month'],
    issueDate: DateTime.parse(map['issue_date']),
    dueDate: DateTime.parse(map['due_date']),
    totalAmount: double.parse(map['total_amount'].toString()),
    status:
        InvoiceStatusExtension.fromValue(map['status'] as String) ??
        InvoiceStatus.kiallitva,
  );

  factory Invoice.createFromMap(
    Map<String, dynamic> map, {
    List<InvoiceItem>? items,
    List<Payment>? payments,
  }) {
    return Invoice(
      id: map['id'],
      flatId: map['flat_id'],
      year: map['year'],
      month: map['month'],
      issueDate: DateTime.parse(map['issue_date']),
      dueDate: DateTime.parse(map['due_date']),
      totalAmount: (map['total_amount'] as num).toDouble(),
      status:
          InvoiceStatusExtension.fromValue(map['status'] as String) ??
          InvoiceStatus.kiallitva,
      items: items ?? [],
      payments: payments ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'flat_id': flatId,
    'year': year,
    'month': month,
    'issue_date': issueDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'total_amount': totalAmount,
    'status': status.value,
  };

  Invoice copyWith({
    String? id,
    String? flatId,
    int? year,
    int? month,
    DateTime? issueDate,
    DateTime? dueDate,
    double? totalAmount,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    List<Payment>? payments,
  }) {
    return Invoice(
      id: id ?? this.id,
      flatId: flatId ?? this.flatId,
      year: year ?? this.year,
      month: month ?? this.month,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      items: items ?? this.items,
      payments: payments ?? this.payments,
    );
  }
}
