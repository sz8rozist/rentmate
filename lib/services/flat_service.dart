import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart';
import 'package:rentmate/models/flat_model.dart';

import '../graphql_error.dart';
import '../models/flat_status.dart';

class FlatService {
  final GraphQLClient client;

  FlatService(this.client);

  Future<Flat?> addFlat(
    String address,
    int price,
    int? landlordId,
  ) async {
    const mutation = r'''
      mutation AddFlat($data: FlatRequestInput!) {
  addFlat(data: $data) {
    id
    address
    price
    status
    images {
      id
      url
      path
    }
  }
}
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'data': {
            'address': address,
            'price': price,
            'landlordId': landlordId,
          },
        },
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
      throw parseGraphQLErrors(result.exception);
    }

    return result.data?['addFlat'] != null
        ? Flat.fromJson(result.data!['addFlat'])
        : null;
  }

  Future<bool> uploadFlatImages(int flatId, List<String> filePaths) async {
    if (filePaths.isEmpty) return false;

    const mutation = r'''
      mutation UploadFlatImages($flatId: Int!, $images: [Upload!]!) {
        uploadFlatImages(flatId: $flatId, images: $images)
      }
    ''';

    // MultipartFile objektumok listája
    final files = await Future.wait(filePaths.map((path) async {
      return await MultipartFile.fromPath(
        'images', // Fontos: a GraphQL paraméter neve
        path,
        filename: path.split('/').last,
      );
    }));

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'flatId': flatId, 'images': files},
      ),
    );

    if (result.hasException) {
      throw parseGraphQLErrors(result.exception);
    }

    return result.data?['uploadFlatImages'] ?? false;
  }

  Future<bool> deleteFlatImage(int imageId) async {
    const mutation = r'''
      mutation DeleteFlatImage($imageId: Int!) {
        deleteFlatImage(imageId: $imageId)
      }
    ''';
    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: {'imageId': imageId}),
    );
    return result.data?['deleteFlatImage'] ?? false;
  }

  Future<Flat?> updateFlat(int flatId, Flat flat) async {
    const mutation = r'''
      mutation UpdateFlat($flatId: Int!, $data: FlatRequestInput!) {
        updateFlat(flatId: $flatId, data: $data) {
          id
          address
          price
          status
          landlord { id name email }
          images { id url }
          tenants { id name email }
          messages { id text createdAt }
        }
      }
    ''';
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'flatId': flatId, 'data': flat.toJson()},
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
      return null;
    }

    return result.data?['updateFlat'] != null
        ? Flat.fromJson(result.data!['updateFlat'])
        : null;
  }

  Future<bool> deleteFlat(int flatId) async {
    const mutation = r'''
      mutation DeleteFlat($flatId: Int!) {
        deleteFlat(flatId: $flatId)
      }
    ''';
    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: {'flatId': flatId}),
    );
    return result.data?['deleteFlat'] ?? false;
  }

  Future<bool> addTenantToFlat(int flatId, int tenantId) async {
    const mutation = r'''
      mutation AddTenantToFlat($flatId: Int!, $tenantId: Int!) {
        addTenantToFlat(flatId: $flatId, tenantId: $tenantId)
      }
    ''';
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'flatId': flatId, 'tenantId': tenantId},
      ),
    );
    return result.data?['addTenantToFlat'] ?? false;
  }

  Future<bool> removeTenantFromFlat(int tenantId) async {
    const mutation = r'''
      mutation RemoveTenantFromFlat($tenantId: Int!) {
        removeTenantFromFlat(tenantId: $tenantId)
      }
    ''';
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'tenantId': tenantId},
      ),
    );
    return result.data?['removeTenantFromFlat'] ?? false;
  }

  Future<Flat?> getFlatById(int id) async {
    const query = r'''
      query FlatById($id: Int!) {
        flatById(id: $id) {
          id
          address
          price
          landlord {
            id
            name
          }
          tenants {
            id
            name
          }
          images {
            id
            url
          }
        }
      }
    ''';

    final result = await client.query(
      QueryOptions(document: gql(query), variables: {'id': id}),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['flatById'];
    if (data == null) return null;
    return Flat.fromJson(data);
  }

  Future<Flat?> getFlatForTenant(int tenantId) async {
    const query = r'''
      query GetFlatForTenant($tenantId: Int!) {
        getFlatForTenant(tenantId: $tenantId) {
          id
          address
          price
          status
          landlord { id name email }
          images { id url }
          tenants { id name email }
          messages { id text createdAt }
        }
      }
    ''';
    final result = await client.query(
      QueryOptions(document: gql(query), variables: {'tenantId': tenantId}),
    );

    if (result.hasException) {
      print(result.exception.toString());
      return null;
    }

    return result.data?['getFlatForTenant'] != null
        ? Flat.fromJson(result.data!['getFlatForTenant'])
        : null;
  }

  Future<List<Flat>> getFlatsForLandlord(int landlordId) async {
    const query = r'''
      query GetFlatsForLandlord($landlordId: Int!) {
        getFlatsForLandlord(landlordId: $landlordId) {
          id
          address
          price
          status
          landlord { id name email role }
        }
      }
    ''';
    final result = await client.query(
      QueryOptions(document: gql(query), variables: {'landlordId': landlordId}),
    );
    if (result.hasException) {
      throw parseGraphQLErrors(result.exception);
    }

    final list = result.data?['getFlatsForLandlord'] as List<dynamic>? ?? [];
    return list.map((e) => Flat.fromJson(e)).toList();
  }
}
