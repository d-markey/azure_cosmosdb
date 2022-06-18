import '_context.dart';

import 'base_document.dart';
import 'client.dart';
import 'database.dart';
import 'partition.dart';
import 'permission.dart';
import 'query.dart';

class Collection {
  Collection(this.database, String name) : url = '${database.url}/colls/$name';

  final Database database;
  final String url;

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
