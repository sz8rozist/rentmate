import 'package:rentmate/models/flat_status.dart';

class Flat {
  final String? id;
  final String address;
  final String? imageUrl;
  final int price;
  final FlatStatus status;
  final String? tenant;

  Flat({
    this.id,
    required this.address,
    this.imageUrl,
    required this.price,
    required this.status,
    this.tenant
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id'] as String,
      address: json['address'] as String,
      price: json['price'],
      status: FlatStatusExtension.fromValue(json['role'] as String) ?? FlatStatus.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'price': price,
      'status': status.value
    };
  }
}