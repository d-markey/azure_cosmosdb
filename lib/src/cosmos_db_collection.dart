import 'base_document.dart';
import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'indexing/partition.dart';
import 'permissions/cosmos_db_permission.dart';
import 'queries/query.dart';
import 'cosmos_db_server.dart';

@Deprecated('Use CosmosDbCollection instead.')
typedef Collection = CosmosDbCollection;

/// Class representing a CosmosDB collection.
class CosmosDbCollection extends BaseDocument {
  CosmosDbCollection(this.database, this.id,
      {this.partitionKeys,
      IndexingPolicy? indexingPolicy,
      GeospatialConfig? geospatialConfig})
      : url = '${database.url}/colls/$id',
        _indexingPolicy = indexingPolicy,
        _geospatialConfig = geospatialConfig;

  /// The collection's parent [CosmosDbDatabase].
  final CosmosDbDatabase database;

  /// The collection's base [url].
  final String url;

  /// Flag indicating whether the collection exists in CosmosDB.
  /// `null` if no check has been made yet.
  bool? get exists => _exists;
  bool? _exists;

  @override
  final String id;

  /// The collection's list of partition keys; mandatory when creating a new [CosmosDbCollection].
  final List<String>? partitionKeys;

  /// The collection's indexing policy.
  IndexingPolicy? _indexingPolicy;
  IndexingPolicy? get indexingPolicy => _indexingPolicy;

  /// The collection's indexing policy.
  GeospatialConfig? _geospatialConfig;

  GeospatialConfig? get geospatialConfig =>
      _geospatialConfig ?? GeospatialConfig.forPolicy(_indexingPolicy);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'partitionKey': {
          "paths": partitionKeys,
        },
        if (_indexingPolicy != null)
          'indexingPolicy': _indexingPolicy!.toJson(),
        if (geospatialConfig != null)
          'geospatialConfig': geospatialConfig!.toJson(),
      };

  /// Use this [CosmosDbPermission] when invoking the CosmosDB API. Using
  /// [CosmosDbPermission] is a way to avoid disclosing the master key in
  /// client applications; to retrieve or create a permission, you should
  /// implement some additional API to be used by your client app. This API
  /// will protect your master keys. Most methods from [CosmosDbCollection]
  /// support an optional [permission] argument, to allow for overriding
  /// this collection-wide [permission].
  void usePermission(CosmosDbPermission permission) {
    _token = permission.token;
  }

  /// Clear the collection-wide permission.
  void clearPermission() {
    _token = null;
  }

  /// Callback to refresh a permission. When the collection-wide
  /// [CosmosDbPermission] expires and a CosmosDB API replies with
  /// a [ForbiddenException] (HTTP error 403), this callback will
  /// be invoked to obtain a new, valid [CosmosDbPermission] that
  /// will replace the expired one.
  FutureCallback<CosmosDbPermission?>? onForbidden;

  String? _token;

  Future<CosmosDbPermission?> _refreshPermission() async {
    CosmosDbPermission? permission;
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

  /// Gets information for this [CosmosDbCollection].
  Future<CosmosDbCollection> getInfo({CosmosDbPermission? permission}) async {
    final coll = await client.get<CosmosDbCollection>(
        url,
        Context(
          type: 'colls',
          token: permission?.token ?? _token,
          throwOnNotFound: true,
          builder: database.collections.fromJson,
        ));
    return coll!;
  }

  /// Gets information for this [CosmosDbCollection].
  Future<void> setIndexingPolicy(IndexingPolicy indexingPolicy,
      {GeospatialConfig? geospatialConfig,
      CosmosDbPermission? permission}) async {
    final prevIndexingPolicy = _indexingPolicy;
    final prevGeospatialConfig = _geospatialConfig;
    _indexingPolicy = indexingPolicy;
    if (geospatialConfig != null) {
      _geospatialConfig = geospatialConfig;
    }
    try {
      await client.put<CosmosDbCollection>(
          url,
          this,
          Context(
            type: 'colls',
            token: permission?.token ?? _token,
            builder: database.collections.fromJson,
          ));
    } catch (ex) {
      _indexingPolicy = prevIndexingPolicy;
      _geospatialConfig = prevGeospatialConfig;
      rethrow;
    }
  }

  /// Finds the document with [id] in this collection. If the document does not exist,
  /// this method returns `null` by default. If `throwOnNotFound` is set to `true`, it
  /// will instead throw a [NotFoundException].
  Future<T?> find<T extends BaseDocument>(String id,
          {bool throwOnNotFound = false,
          CosmosDbPartition? partition,
          CosmosDbPermission? permission}) =>
      client.get<T>(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partition: partition ?? CosmosDbPartition(id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Lists all documents from this collection.
  Future<Iterable<T>> list<T extends BaseDocument>(
          {CosmosDbPartition? partition, CosmosDbPermission? permission}) =>
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
          {CosmosDbPermission? permission}) =>
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

  /// Loads documents from this collection matching the provided [query].
  Future<dynamic> rawQuery(Query query, {CosmosDbPermission? permission}) =>
      client.rawQuery(
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
          {CosmosDbPartition? partition, CosmosDbPermission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          partition: partition ?? CosmosDbPartition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Adds or updates (replaces) a [document] in this collection.
  Future<T> upsert<T extends BaseDocument>(T document,
          {CosmosDbPartition? partition, CosmosDbPermission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          headers: {'x-ms-documentdb-is-upsert': 'true'},
          partition: partition ?? CosmosDbPartition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Updates (replaces) a [document] in this collection. If the [document] is a
  /// [BaseDocumentWithEtag], its [BaseDocumentWithEtag.etag] must be known.
  Future<T> replace<T extends BaseDocument>(T document,
          {CosmosDbPartition? partition, CosmosDbPermission? permission}) =>
      client.put(
        '$url/docs/${document.id}',
        document,
        Context(
          type: 'docs',
          headers: (document is BaseDocumentWithEtag)
              ? {'if-match': document.etag}
              : null,
          partition: partition ?? CosmosDbPartition(document.id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Deletes the document with [id] from this collection. If the document does not
  /// exist, this method returns `true` by default. If [throwOnNotFound] is set to
  /// `true`, it will instead throw a [NotFoundException].
  Future<bool> delete(String id,
          {bool throwOnNotFound = false,
          CosmosDbPartition? partition,
          CosmosDbPermission? permission}) =>
      client.delete(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partition: partition ?? CosmosDbPartition(id),
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );
}

// internal use
extension CollectionExt on CosmosDbCollection {
  void setExists(bool exists) => _exists = exists;

  Client get client => database.client;
}
