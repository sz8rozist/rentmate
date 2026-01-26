import '../models/flat_model.dart';
import '../models/flat_status.dart';
import '../rest_api_config.dart';
import 'file_upload_service.dart';

class FlatService {
  final ApiService apiService;
  final FileUploadService fileUploadService;

  FlatService({required this.apiService, required this.fileUploadService});

  /// Add Flat
  Future<Flat> addFlat(String address, int price, int landlordId, {FlatStatus status = FlatStatus.available}) async {
    final data = await apiService.post('/flat-controller', {
      'address': address,
      'price': price,
      'landlordId': landlordId,
      'status': status.value,
    });

    return Flat.fromJson(data);
  }

  /// Upload Single Image
  Future<bool> uploadSingleImage(int flatId, String filePath) async {
    return await fileUploadService.uploadFile(
      '/flat-controller/$flatId/images',
      filePath,
      fileFieldName: 'image',
    );
  }

  /// Delete Flat Image
  Future<bool> deleteFlatImage(int imageId) async {
    final data = await apiService.delete('/flat-controller/images/$imageId');
    return data['success'] ?? true; // backend lehet true/false vagy maga az object
  }

  /// Update Flat
  Future<Flat> updateFlat(int flatId, {String? address, int? price, FlatStatus? status}) async {
    final body = <String, dynamic>{};
    if (address != null) body['address'] = address;
    if (price != null) body['price'] = price;
    if (status != null) body['status'] = status.value;

    final data = await apiService.put('/flat-controller/$flatId', body);
    return Flat.fromJson(data);
  }

  /// Delete Flat
  Future<bool> deleteFlat(int flatId) async {
    final data = await apiService.delete('/flat-controller/$flatId');
    return data['success'] ?? true;
  }

  /// Get Flat by ID
  Future<Flat> getFlatById(int id) async {
    final data = await apiService.get('/flat-controller/$id');
    return Flat.fromJson(data);
  }

  /// Get Flat for Tenant
  Future<Flat?> getFlatForTenant(int tenantId) async {
    try {
      final data = await apiService.get('/flat-controller/tenant/$tenantId');
      return data != null ? Flat.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// Get Flats for Landlord
  Future<List<Flat>> getFlatsForLandlord(int landlordId) async {
    final data = await apiService.get('/flat-controller/landlord/$landlordId');
    final list = data as List<dynamic>? ?? [];
    return list.map((e) => Flat.fromJson(e)).toList();
  }

  /// Assign Tenant to Flat
  Future<bool> addTenantToFlat(int flatId, int tenantId) async {
    final data = await apiService.post('/flat-controller/$flatId/tenants', {
      'tenantId': tenantId,
    });
    return data['success'] ?? true;
  }

  /// Remove Tenant from Flat
  Future<bool> removeTenantFromFlat(int tenantId) async {
    final data = await apiService.delete('/flat-controller/tenants/$tenantId');
    return data['success'] ?? true;
  }
}
