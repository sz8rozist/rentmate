import '../models/user_model.dart';
import '../rest_api_config.dart';

class UserService {
  final ApiService apiService;
  UserService(this.apiService);

  Future<List<UserModel>> getTenant(String name) async {
    try {
      // Ha üres, akkor nem küldünk query param-et
      final queryParams = name.isEmpty ? null : {'name': name};

      final data = await apiService.get('/tenants', queryParameters: queryParams);

      final tenants = (data as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return tenants;
    } catch (e) {
      print('Error fetching tenants: $e');
      rethrow;
    }
  }
}
