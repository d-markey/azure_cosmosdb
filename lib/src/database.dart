import 'package:http/http.dart' as http;

import '_context.dart';

import 'base_document.dart';
import 'client.dart';
import 'collection.dart';
import 'users.dart';

class Database {
  Database(this.client, String name) : url = 'dbs/$name';

  Database.open(
    String urlOrAccount,
    String name, {
    String? masterKey,
    http.Client? httpClient,
  }) : this(
            Client(
              urlOrAccount,
              masterKey: masterKey,
              httpClient: httpClient,
            ),
            name);

  final Client client;
  final String url;

  Future<Map<String, dynamic>?> getInfo() =>
      client.getJson(url, Context(type: 'dbs'));

  Collection getCollection(String collection) => Collection(this, collection);

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      client.registerBuilder<T>(builder);

  late final Users users = Users(this);
}
