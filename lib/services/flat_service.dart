
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rentmate/models/flat_model.dart';
import 'package:rentmate/services/file_upload_service.dart';

import '../graphql_error.dart';

class FlatService {
  final GraphQLClient client;
  final FileUploadService fileUploadService;

  FlatService(this.client, this.fileUploadService);

  Future<Flat> addFlat(String address, int price, int? landlordId) async {
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
      filename
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

    return Flat.fromJson(result.data!['addFlat']);
  }

  Future<bool> uploadSingleImage(int flatId, String filePath) async {
    const mutation = r'''
    mutation UploadFlatImage($flatId: Int!, $image: Upload!) {
      uploadFlatImage(flatId: $flatId, image: $image)
    }
  ''';
    final success = await fileUploadService.uploadSingleFile(
      mutation: mutation,
      variables: {'flatId': flatId},
      filePath: filePath,
      fileVariableName: 'image', // GraphQL paraméter neve
    );

    return success;
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

  Future<Flat> updateFlat(int flatId, Flat flat) async {
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
        variables: {'flatId': flatId, 'data': flat.toMap()},
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
      throw parseGraphQLErrors(result.exception);
    }

    return Flat.fromJson(result.data!['updateFlat']);
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

  Future<Flat> getFlatById(int id) async {
    const query = r'''
      query FlatById($id: Int!) {
        flatById(id: $id) {
          id
          address
          price
          status
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
            filename
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
          images { id url filename flatId }
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
