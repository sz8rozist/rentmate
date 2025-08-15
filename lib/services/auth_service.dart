import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rentmate/GraphQLConfig.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/models/user_role.dart';

import '../graphql_error.dart';

class AuthService {
  final GraphQLClient client;
  final FlutterSecureStorage storage;

  AuthService({required this.client, required this.storage});

  Future<String> login(String email, String password) async {
    const mutation = r'''
      mutation Login($email: String!, $password: String!) {
        login(email: $email, password: $password)
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'email': email, 'password': password},
      ),
    );

    if (result.hasException) {
      print(result);
      throw parseGraphQLErrors(result.exception);
    }
    final token = result.data?['login'];
    if (token == null) throw Exception('Login failed');

    await storage.write(key: 'access_token', value: token);
    return token;
  }

  Future<UserModel> register(String email, String password, String name, UserRole role) async {
    const mutation = r'''
    mutation Register($data: RegisterInput!) {
      register(data: $data) {
        id
        email
        name
        role
      }
    }
  ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'data': {
            'email': email,
            'role': role.value,
            'password': password,
            'name': name,
          },
        },
      ),
    );

    if (result.hasException) {
      print("GraphQL Exception: ${result.exception.toString()}");
      print("Full Exception Details: ${result.exception!.graphqlErrors}");
      throw parseGraphQLErrors(result.exception);
    }


    return UserModel.fromJson(result.data?['register']);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

}


