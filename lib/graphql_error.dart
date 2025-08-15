import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLErrorItem {
  final String field;
  final String message;

  GraphQLErrorItem({required this.field, required this.message});
}

class GraphQLErrorResponse implements Exception {
  final String generalMessage;
  final List<GraphQLErrorItem> fieldErrors;

  GraphQLErrorResponse({
    required this.generalMessage,
    required this.fieldErrors,
  });

  @override
  String toString() {
    if (fieldErrors.isEmpty) return generalMessage;
    return "$generalMessage\n${fieldErrors.map((e) => "${e.field}: ${e.message}").join("\n")}";
  }
}

GraphQLErrorResponse parseGraphQLErrors(OperationException? exception) {
  if (exception == null) {
    return GraphQLErrorResponse(generalMessage: "Unknown error", fieldErrors: []);
  }

  List<GraphQLErrorItem> fieldErrors = [];
  String generalMessage = "";

  for (final error in exception.graphqlErrors) {
    final validationErrors = error.extensions?['validationErrors'];

    if (validationErrors != null && validationErrors is Map) {
      validationErrors.forEach((field, errors) {
        if (errors is List) {
          for (final e in errors) {
            fieldErrors.add(GraphQLErrorItem(field: field, message: e.toString()));
          }
        }
      });
    } else {
      generalMessage += "${error.message} ";
    }
  }

  if (generalMessage.isEmpty) {
    generalMessage = "Hiba történt!";
  }

  return GraphQLErrorResponse(
    generalMessage: generalMessage.trim(),
    fieldErrors: fieldErrors,
  );
}
