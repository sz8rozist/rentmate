import 'package:rentmate/models/flat_image.dart';
import 'package:rentmate/models/flat_status.dart';
import 'package:rentmate/models/user_model.dart';

class Flat {
  final String? id;
  final String address;
  final List<FlatImage> images;
  final int price;
  final FlatStatus status;
  final String landLord;
  final List<UserModel>? tenants;

  Flat({
    this.id,
    required this.address,
    required this.images,
    required this.price,
    required this.status,
    required this.landLord,
    this.tenants,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id'] as String?,
      address: json['address'] as String,
      images:
          (json['images'] as List<dynamic>)
              .map((item) => FlatImage.fromJson(item as Map<String, dynamic>))
              .toList(),
      price: json['price'] as int,
      status:
          FlatStatusExtension.fromValue(json['status'] as String) ??
          FlatStatus.active,
      landLord: json['landlord_user_id'],
      tenants:
      (json['flats_for_rent'] as List<dynamic>?)
          ?.map((item) => UserModel.fromJson((item as Map<String, dynamic>)['tenant'] as Map<String, dynamic>))
          .toList()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'images': images.map((img) => img.toJson()).toList(),
      'price': price,
      'status': status.value,
      'landLord': landLord,
      'tenants': tenants?.map((tenant) => tenant.toJson()).toList(),
    };
  }

  Flat copyWith({
    String? id,
    String? address,
    int? price,
    FlatStatus? status,
    String? landLord,
    List<FlatImage>? images,
    List<UserModel>? tenants
  }) {
    return Flat(
      id: id ?? this.id,
      address: address ?? this.address,
      status: status ?? this.status,
      landLord: landLord ?? this.landLord,
      images: images ?? this.images,
      price: price ?? this.price,
      tenants: tenants ?? this.tenants
    );
  }
}
