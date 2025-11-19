import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/models/message_model.dart';
import 'package:rentmate/models/user_model.dart';

class Flat {
  final int? id;
  final String address;
  final List<FlatImage>? images;
  final int price;
  final FlatStatus status;
  final UserModel? landlord;
  final List<UserModel>? tenants;
  final List<MessageModel>? messages;

  Flat({
    this.id,
    required this.address,
    this.images,
    required this.price,
    required this.status,
    this.landlord,
    this.messages,
    this.tenants,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      price:
          json['price'] is int
              ? json['price']
              : int.tryParse(json['price'].toString()) ?? 0,
      address: json['address'] as String,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((item) => FlatImage.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      status:
          FlatStatusExtension.fromValue(json['status'] as String) ??
          FlatStatus.available,
      landlord:
          (json['landlord'] != null && json['landlord'] is Map<String, dynamic>)
              ? UserModel.fromJson(json['landlord'] as Map<String, dynamic>)
              : null,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map(
                (item) => MessageModel.fromJson(
                  (item as Map<String, dynamic>)['message']
                      as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      tenants:
          (json['tenants'] as List<dynamic>?)
              ?.map(
                (item) => UserModel.fromJson(
                  (item as Map<String, dynamic>)['tenant']
                      as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'images': images?.map((img) => img.toJson()).toList(),
      'price': price,
      'status': status.value,
      'landlord': landlord?.toJson(),
      'messages': messages?.map((msg) => msg.toJson()).toList(),
      'tenants': tenants?.map((tenant) => tenant.toJson()).toList(),
    };
  }

  Flat copyWith({
    int? id,
    String? address,
    int? price,
    FlatStatus? status,
    UserModel? landlord,
    List<FlatImage>? images,
    List<UserModel>? tenants,
  }) {
    return Flat(
      id: id ?? this.id,
      address: address ?? this.address,
      status: status ?? this.status,
      landlord: landlord ?? this.landlord,
      images: images ?? this.images,
      price: price ?? this.price,
      tenants: tenants ?? this.tenants,
    );
  }
}
