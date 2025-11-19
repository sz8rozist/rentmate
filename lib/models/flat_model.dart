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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'images': images?.map((e) => e.toMap()).toList(),
      'price': price,
      'status': status.name,        // enum --> string
      'landlord': landlord?.toJson(),
      'tenants': tenants?.map((e) => e.toJson()).toList(),
      'messages': messages?.map((e) => e.toJson()).toList(),
    };
  }

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: int.tryParse(json['id']),
      address: json['address'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => FlatImage.fromJson(e))
          .toList(),
      price: int.tryParse(json['price'].toString()) ?? 0,
      status: FlatStatusExtension.fromValue(json['status']),
      landlord: json['landlord'] != null
          ? UserModel.fromJson(json['landlord'])
          : null,
      tenants: (json['tenants'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e))
          .toList(),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageModel.fromJson(e))
          .toList(),
    );
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
