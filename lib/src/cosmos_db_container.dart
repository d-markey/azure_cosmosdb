import 'package:meta/meta.dart';

import '_internal/_http_header.dart';
import 'base_document.dart';
import 'batch/batch.dart';
import 'batch/batch_response.dart';
import 'batch/cross_partition_batch.dart';
import 'batch/transactional_batch.dart';
import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_server.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'partition/partition_key.dart';
import 'partition/partition_key_range.dart';
import 'partition/partition_key_spec.dart';
import 'patch/patch.dart';
import 'permissions/cosmos_db_permission.dart';
import 'queries/query.dart';

/// Class representing a CosmosDB container.
class CosmosDbContainer extends BaseDocument {
  CosmosDbContainer(this.database, this.id,
      {PartitionKeySpec? partitionKeySpec,
      IndexingPolicy? indexingPolicy,
      GeospatialConfig? geospatialConfig})
      : url = '${database.url}/colls/$id',
        partitionKeySpec = partitionKeySpec ?? PartitionKeySpec.id,
        _indexingPolicy = indexingPolicy,
        _geospatialConfig = geospatialConfig;

  /// The container's parent [CosmosDbDatabase].
  final CosmosDbDatabase database;

  /// The container's base [url].
  final String url;

  /// Flag indicating whether the container exists in CosmosDB.
  /// `null` if no check has been made yet.
  bool? get exists => _exists;
  bool? _exists;

  @override
  final String id;

  /// The container's partition key specification.
  final PartitionKeySpec partitionKeySpec;

  /// The container's indexing policy.
  IndexingPolicy? get indexingPolicy => _indexingPolicy;
  IndexingPolicy? _indexingPolicy;

  /// The container's geospatial configuration.
  GeospatialConfig? get geospatialConfig =>
      _geospatialConfig ?? GeospatialConfig.forPolicy(_indexingPolicy);
  GeospatialConfig? _geospatialConfig;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'partitionKey': partitionKeySpec.toJson(),
        if (_indexingPolicy != null)
          'indexingPolicy': _indexingPolicy!.toJson(),
        if (geospatialConfig != null)
          'geospatialConfig': geospatialConfig!.toJson(),
      };

  /// Use this [CosmosDbPermission] when invoking the CosmosDB API. Using
  /// [CosmosDbPermission] is a way to avoid disclosing the master key in
  /// client applications; to retrieve or create a permission, you should
  /// implement some additional API to be used by your client app. This API
  /// will protect your master keys. Most methods from [CosmosDbContainer]
  /// support an optional [permission] argument, to allow for overriding
  /// this container-wide [permission].
  void usePermission(CosmosDbPermission permission) {
    _token = permission.token;
  }

  /// Clear the container-wide permission.
  void clearPermission() {
    _token = null;
  }

  /// Callback to refresh a permission. When the container-wide
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

  final _builders = <Type, DocumentBuilder>{};

  /// Register a [DocumentBuilder] for specified type `T`.
  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      _builders[T] = builder;

  /// Gets information for this [CosmosDbContainer].
  Future<CosmosDbContainer> getInfo({CosmosDbPermission? permission}) async {
    final coll = await client.get<CosmosDbContainer>(
        url,
        Context(
          type: 'colls',
          token: permission?.token ?? _token,
          throwOnNotFound: true,
          builder: database.containers.fromJson,
        ));
    return coll!;
  }

  final _pkRanges = <PartitionKeyRange>[];

  /// Gets the partition key ranges for this [CosmosDbContainer].
  Future<Iterable<PartitionKeyRange>> getPkRanges(
      {CosmosDbPermission? permission, bool force = false}) async {
    if (_pkRanges.isEmpty || force) {
      _pkRanges.clear();
      _pkRanges.addAll(await client.getMany<PartitionKeyRange>(
          '$url/pkranges',
          'PartitionKeyRanges',
          Context(
              resId: url,
              type: 'pkranges',
              token: permission?.token ?? _token,
              throwOnNotFound: true,
              builder: PartitionKeyRange.fromJson)));
    }
    return _pkRanges;
  }

  /// Gets information for this [CosmosDbContainer].
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
      await client.put<CosmosDbContainer>(
          url,
          this,
          Context(
            type: 'colls',
            token: permission?.token ?? _token,
            builder: database.containers.fromJson,
          ));
    } catch (ex) {
      _indexingPolicy = prevIndexingPolicy;
      _geospatialConfig = prevGeospatialConfig;
      rethrow;
    }
  }

  /// Finds the document with [id] in this container. If the document does not exist,
  /// this method returns `null` by default. If [throwOnNotFound] is set to `true`, it
  /// will throw a [NotFoundException] instead.
  Future<T?> find<T extends BaseDocument>(dynamic id, PartitionKey partitionKey,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      client.get<T>(
        '$url/docs/$id',
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partitionKey: partitionKey,
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Returns the latest version of the document.
  Future<T?> get<T extends BaseDocument>(T document,
          {bool throwOnNotFound = false,
          PartitionKey? partitionKey,
          CosmosDbPermission? permission}) =>
      client
          .get<T>(
            '$url/docs/${document.id}',
            Context(
              type: 'docs',
              throwOnNotFound: throwOnNotFound,
              headers: (document is EtagMixin)
                  ? {HttpHeader.ifNoneMatch: document.etag}
                  : null,
              partitionKey: partitionKey ??
                  partitionKeySpec.from(document) ??
                  PartitionKey.all,
              builders: _builders,
              token: permission?.token ?? _token,
              onForbidden: _refreshPermission,
            ),
          )
          .onError<NotModifiedException>((error, stackTrace) => document);

  /// Lists all documents from this container.
  Future<Iterable<T>> list<T extends BaseDocument>(
          {PartitionKey? partitionKey, CosmosDbPermission? permission}) =>
      client.getMany<T>(
        '$url/docs',
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          partitionKey: partitionKey ?? PartitionKey.all,
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Loads documents from this container matching the provided [query].
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
          builders: _builders,
          onForbidden: _refreshPermission,
        ),
      );

  /// Loads documents from this container matching the provided [query].
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

  /// Adds a new [document] to this container.
  Future<T> add<T extends BaseDocument>(T document,
          {PartitionKey? partitionKey, CosmosDbPermission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Adds or updates (replaces) a [document] in this container.
  Future<T> upsert<T extends BaseDocument>(T document,
          {PartitionKey? partitionKey, CosmosDbPermission? permission}) =>
      client.post(
        '$url/docs',
        document,
        Context(
          type: 'docs',
          resId: url,
          headers: HttpHeader.isUpsert,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Updates (replaces) a [document] in this container. If the [document] has
  /// [EtagMixin], its [EtagMixin.etag] must be known.
  Future<T> replace<T extends BaseDocument>(T document,
          {bool checkEtag = true,
          PartitionKey? partitionKey,
          CosmosDbPermission? permission}) =>
      client.put(
        '$url/docs/${document.id}',
        document,
        Context(
          type: 'docs',
          headers: (document is EtagMixin && checkEtag)
              ? {HttpHeader.ifMatch: document.etag}
              : null,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Updates (patches) a [document] in this container by applying the [patch]
  /// operations.
  Future<T> patch<T extends BaseDocument>(T document, Patch patch,
          {PartitionKey? partitionKey, CosmosDbPermission? permission}) =>
      client.patch(
        '$url/docs/${document.id}',
        patch,
        Context(
          type: 'docs',
          headers: HttpHeader.patchPayload,
          partitionKey: partitionKey ??
              partitionKeySpec.from(document) ??
              PartitionKey.all,
          builders: _builders,
          token: permission?.token ?? _token,
          onForbidden: _refreshPermission,
        ),
      );

  /// Deletes the document from this container. If the document does not exist,
  /// this method returns `true` by default. If [throwOnNotFound] is set to
  /// `true`, it will instead throw a [NotFoundException]. If the [document] is
  /// provided, its attributes take over the [id] value. If it has [EtagMixin],
  /// its [EtagMixin.etag] must be known.
  Future<bool> delete<T extends BaseDocument>(
      {String? id,
      T? document,
      bool throwOnNotFound = false,
      bool checkEtag = true,
      PartitionKey? partitionKey,
      CosmosDbPermission? permission}) {
    if (document == null && id == null) {
      throw ApplicationException('Missing document and document id.');
    }
    id = document?.id ?? id;
    if (id == null) {
      throw ApplicationException('Missing document id');
    }
    return client.delete(
      '$url/docs/$id',
      Context(
        type: 'docs',
        throwOnNotFound: throwOnNotFound,
        headers: (document is EtagMixin && checkEtag)
            ? {HttpHeader.ifMatch: document.etag}
            : null,
        partitionKey: partitionKey ??
            (document == null
                ? PartitionKey.all
                : partitionKeySpec.from(document)),
        token: permission?.token ?? _token,
        onForbidden: _refreshPermission,
      ),
    );
  }

  /// Prepare a batch for this container.
  Batch prepareBatch(
          {PartitionKey? partitionKey, bool continueOnError = true}) =>
      TransactionalBatch(this,
          continueOnError: continueOnError, partitionKey: partitionKey);

  /// Prepare a batch for this container (atomic).
  Batch prepareAtomicBatch({PartitionKey? partitionKey}) =>
      TransactionalBatch.atomic(this, partitionKey: partitionKey);

  /// Prepare a batch for this container (cross-partition).
  Batch prepareCrossPartitionBatch({PartitionKey? partitionKey}) =>
      CrossPartitionBatch(this, partitionKey: partitionKey);

  /// Executes the batch in this container.
  Future<BatchResponse> execute(TransactionalBatch batch,
      {CosmosDbPermission? permission}) async {
    if (batch.operations.isEmpty) {
      return BatchResponse();
    } else {
      await getPkRanges(permission: permission);
      return await client.batch(
        '$url/docs',
        batch,
        _pkRanges,
        Context(
          type: 'docs',
          resId: url,
          token: permission?.token ?? _token,
          builders: _builders,
          onForbidden: _refreshPermission,
        ),
      );
    }
  }
}

// internal use
@internal
extension CosmosDbContainerInternalExt on CosmosDbContainer {
  void setExists(bool exists) => _exists = exists;

  Client get client => database.client;
}
