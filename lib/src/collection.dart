import 'package:azure_cosmosdb/src/indexing/indexing_policy.dart';

import 'impl/_client.dart';
import 'impl/_context.dart';

import 'base_document.dart';
import 'database.dart';
import 'exceptions.dart';
import 'partition.dart';
import 'permission.dart';
import 'query.dart';
import 'server.dart';

/// Class representing a CosmosDB collection.
class Collection extends BaseDocument {
  Collection(this.database, this.id, {this.partitionKeys, this.indexingPolicy})
      : url = '${database.url}/colls/$id';

  /// The collection's parent [Database].
  final Database database;

  /// The collection's base [url].
  final String url;

  /// Flag indicating whether the collection exists in CosmosDB.
  /// `null` if no check has been made yet.
  bool? get exists => _exists;
  bool? _exists;

  @override
  final String id;

  /// The collection's list of partition keys; mandatory when creating a new [Collection].
  final List<String>? partitionKeys;

  /// The collection's indexing policy.
  final IndexingPolicy? indexingPolicy;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        if (partitionKeys != null && partitionKeys!.isNotEmpty)
          'partitionKey': {
            "paths": partitionKeys,
            "kind": "Hash",
            "Version": 2,
          },
        if (indexingPolicy != null) 'indexingPolicy': indexingPolicy!.toJson(),
      };

  /// Use this [Permission] when invoking the CosmosDB API. Using [Permission] is a way to
  /// avoid disclosing the master key in client applications; to retrieve or create a
  /// permission, you should implement some additional API to be used by your client app.
  /// This API will protect your master keys. Most methods from [Collection] support an
  /// optional [permission] argument, to allow for overriding this collection-wide
  /// [permission].
  void usePermission(Permission permission) {
    _token = permission.token;
  }

  /// Callback to refresh a permission. When the collection-wide [Permission] expires and
  /// and a CosmosDB API replies with a [ForbiddenException] (HTTP error 403), this callback
  /// will be invoked to obtain a new, valid [Permission] that will replace the expired one.
  FutureCallback<Permission?>? onForbidden;

  String? _token;

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

  /// Register a [DocumentBuilder] for specified type `T`.
  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      database.registerBuilder<T>(builder);

  /// Gets information for this [Collection].
  Future<Map<String, dynamic>?> getInfo({Permission? permission}) =>
      client.getJson(
          url,
          Context(
            type: 'colls',
            token: permission?.token ?? _token,
          ));

  /// Finds the document with [id] in this collection. If the document does not exist,
  /// this method returns `null` by default. If `throwOnNotFound` is set to `true`, it
  /// will instead throw a [NotFoundException].
  Future<T?> find<T extends BaseDocument>(String id,
          {bool throwOnNotFound = false,
          Partition? partition,
          Permission? permission}) =>
      client.get<T>(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partition: partition ?? Partition(id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Lists all documents from this collection.
  Future<Iterable<T>> list<T extends BaseDocument>(
          {Partition? partition, Permission? permission}) =>
      client.getMany<T>(
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

  /// Loads documents from this collection matching the provided [query].
  Future<Iterable<T>> query<T extends BaseDocument>(Query query,
          {Permission? permission}) =>
      client.query<T>(
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

  /// Adds a new [document] to this collection.
  Future<T> add<T extends BaseDocument>(T document,
          {Partition? partition, Permission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          partition: partition ?? Partition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Adds or updates (replaces) a [document] in this collection.
  Future<T> upsert<T extends BaseDocument>(T document,
          {Partition? partition, Permission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          headers: {
            'x-ms-documentdb-is-upsert': 'true',
          },
          partition: partition ?? Partition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Updates (replaces) a [document] in this collection. The [document] must be a
  /// [BaseDocumentWithEtag] and its [BaseDocumentWithEtag.etag] must be known.
  Future<T> replace<T extends BaseDocumentWithEtag>(T document,
          {Partition? partition, Permission? permission}) =>
      client.put(
        '$url/docs/${document.id}',
        document,
        Context(
          type: 'docs',
          headers: {
            'if-match': document.etag,
          },
          partition: partition ?? Partition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Deletes the document with [id] from this collection. If the document does not
  /// exist, this method returns `true` by default. If [throwOnNotFound] is set to
  /// `true`, it will instead throw a [NotFoundException].
  Future<bool> delete(String id,
          {bool throwOnNotFound = false,
          Partition? partition,
          Permission? permission}) =>
      client.delete(
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
extension CollectionExt on Collection {
  void setExists(bool exists) => _exists = exists;

  Client get client => database.client;
}
