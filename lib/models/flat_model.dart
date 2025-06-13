class Flat {
  final String title;
  final String address;
  final String imageUrl;
  final String rent;
  final String status;
  final String? tenant;

  Flat({
    required this.title,
    required this.address,
    required this.imageUrl,
    required this.rent,
    required this.status,
    this.tenant
  });
}