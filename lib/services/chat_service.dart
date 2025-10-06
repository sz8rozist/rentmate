import 'dart:io';

import 'package:http/http.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql_error.dart';
import '../models/message_model.dart';

class ChatService {
  final GraphQLClient client;

  ChatService(this.client);

  // Üzenet küldés
  Future<void> sendMessage(
    int flatId,
    int senderUserId,
    String content,
    List<File>? files,
  ) async {
    final mutation = '''
  mutation CreateMessageWithFiles(\$input: CreateMessageInput!, \$files: [Upload!]) {
    createMessageWithFiles(input: \$input, files: \$files) {
      id
      content
      imageUrls
      createdAt
    }
  }
  ''';

    List<MultipartFile>? gqlFiles;
    if (files != null && files.isNotEmpty) {
      gqlFiles = [];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        gqlFiles.add(MultipartFile.fromBytes(
          'file',
          bytes,
          filename: f.path.split('/').last,
        ));
      }
    }

    await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'input': {
            'flatId': flatId,
            'senderId': senderUserId,
            'content': content,
          },
          'files': gqlFiles,
        },
      ),
    );
  }

  Future<List<MessageModel>> fetchInitialMessages(int flatId) async {
    final query = '''
    query Messages(\$flatId: Int!) {
      messages(flatId: \$flatId) {
        id
        content
        imageUrls
        createdAt
      }
    }
  ''';

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: {'flatId': flatId},
      ),
    );

    if(result.hasException){
      print(result.exception);
      throw parseGraphQLErrors(result.exception);
    }

    final data = result.data!['messages'] as List<dynamic>;
    return data.map((e) => MessageModel.fromJson(e)).toList();

  }


  Stream<MessageModel> subscribeToMessages(int flatId) {
    final subscription = '''
      subscription OnMessageAdded(\$flatId: Int!) {
        messageAdded(flatId: \$flatId) {
          id
          content
          imageUrls
          createdAt
        }
      }
    ''';

    final options = SubscriptionOptions(
      document: gql(subscription),
      variables: {'flatId': flatId},
    );

    return client.subscribe(options).map((result) {
      if (result.hasException) {
        throw result.exception!;
      }

      final data = result.data?['messageAdded'];
      if (data == null) {
        throw Exception('No message data received');
      }

      return MessageModel.fromJson(data);
    });
  }
}
