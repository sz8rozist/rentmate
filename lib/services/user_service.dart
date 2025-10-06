import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rentmate/graphql_error.dart';
import '../models/user_model.dart';

class UserService {
  final GraphQLClient client;

  UserService(this.client);

  Future<List<UserModel>> getTenant(String name) async {
    const query = r'''
      query GetTenants($input: GetTenantsInput) {
        tenants(input: $input) {
          id
          name
          email
        }
      }
    ''';

    final variables = {
      'input': name.isEmpty ? null : {'name': name}
    };

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      print(result.exception);
      throw parseGraphQLErrors(result.exception);
    }

    final data = result.data!['tenants'] as List<dynamic>;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
