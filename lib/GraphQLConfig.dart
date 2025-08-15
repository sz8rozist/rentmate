import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final tokenProvider = StateProvider<String?>((ref) => null);
final graphQLClientProvider = Provider<ValueNotifier<GraphQLClient>>((ref) {
  final token = ref.watch(tokenProvider);

  final httpLink = HttpLink('http://localhost:3000/graphql');
  Link link = httpLink;

  if (token != null && token.isNotEmpty) {
    final authLink = AuthLink(getToken: () async => 'Bearer $token');
    link = authLink.concat(httpLink);
  }

  return ValueNotifier(
    GraphQLClient(link: link, cache: GraphQLCache(store: InMemoryStore())),
  );
});
