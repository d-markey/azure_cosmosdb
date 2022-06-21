import '_context.dart';

import 'base_document.dart';
import 'client.dart';
import 'collection.dart';
import 'collections.dart';
import 'users.dart';

class Database extends BaseDocument {
  Database(this.client, this.id) : url = 'dbs/$id';

  final Client client;
  final String url;

  bool? _exists;
  bool? get exists => _exists;

  @override
  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};

  Future<Map<String, dynamic>?> getInfo() =>
      client.getJson(url, Context(type: 'dbs'));

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      client.registerBuilder<T>(builder);

  late final collections = Collections(this);

  late final Users users = Users(this);
}

// internal use
extension DbExistsExt on Database {
  void setExists(bool exists) => _exists = exists;
}
