import '_context.dart';

import 'base_document.dart';
import 'database.dart';
import 'partition.dart';
import 'permission.dart';
import 'query.dart';
import 'server.dart';

class Collection extends BaseDocument {
  Collection(this.database, this.id, {this.partitionKeys})
      : url = '${database.url}/colls/$id';

  final Database database;
  final String url;

  bool? _exists;
  bool? get exists => _exists;

  @override
  final String id;

  final List<String>? partitionKeys;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        if (partitionKeys != null && partitionKeys!.isNotEmpty)
          'partitionKey': {"paths": partitionKeys, "kind": "Hash", "Version": 2}
      };

  String? _token;
  FutureCallback<Permission?>? onForbidden;

  void usePermission(Permission permission) {
    _token = permission.token;
  }

  Future<Permission?> _refreshPermission() async {
    Permission? permission;
    final callback = onForbidden;
    if (_token != null && callback != null) {
      permission = await callback();
      if (permission != null) {
        _token = permission.token;
      }
    }
    return permission;
  }

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      database.registerBuilder<T>(builder);

  Future<Map<String, dynamic>?> getInfo() =>
      database.client.getJson(url, Context(type: 'colls'));

  Future<T?> find<T extends BaseDocument>(String id,
          {bool throwOnNotFound = false,
          Partition? partition,
          Permission? permission}) =>
      database.client.get<T>(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partition: partition ?? Partition(id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<Iterable<T>> list<T extends BaseDocument>(
          {Partition? partition, Permission? permission}) =>
      database.client.getMany<T>(
        '$url/docs',
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          partition: partition,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<Iterable<T>> query<T extends BaseDocument>(Query query,
          {Permission? permission}) =>
      database.client.query<T>(
        '$url/docs',
        query,
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<T> add<T extends BaseDocument>(T data,
          {Partition? partition, Permission? permission}) =>
      database.client.post(
        '$url/docs',
        data,
        Context(
          type: 'docs',
          resId: url,
          partition: partition ?? Partition(data.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<T> upsert<T extends BaseDocument>(T data,
          {Partition? partition, Permission? permission}) =>
      database.client.post(
        '$url/docs',
        data,
        Context(
          type: 'docs',
          resId: url,
          headers: {
            'x-ms-documentdb-is-upsert': 'true',
          },
          partition: partition ?? Partition(data.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<T> replace<T extends BaseDocumentWithEtag>(T data,
          {Partition? partition, Permission? permission}) =>
      database.client.put(
        '$url/docs/${data.id}',
        data,
        Context(
          type: 'docs',
          headers: {
            'if-match': data.etag,
          },
          partition: partition ?? Partition(data.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  Future<bool> delete(String id,
          {bool throwOnNotFound = false,
          Partition? partition,
          Permission? permission}) =>
      database.client.delete(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partition: partition ?? Partition(id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );
}

// internal use
extension CollExistsExt on Collection {
  void setExists(bool exists) => _exists = exists;
}
