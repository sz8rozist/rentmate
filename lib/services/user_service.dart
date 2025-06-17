import 'package:rentmate/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<UserModel>> getTenant(String name) async {
    print(name);
    if (name.isEmpty) {
      final response = await _client.from('available_tenants').select();
      return (response as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }else{
      final response = await _client
          .from('available_tenants')
          .select()
          .ilike('name', '%$name%');

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}
