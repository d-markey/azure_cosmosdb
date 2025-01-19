import 'package:meta/meta.dart';

import '_internal/_extensions.dart';
import '_internal/_http_header.dart';
import 'access_control/cosmos_db_access_control.dart';
import 'access_control/cosmos_db_authorization.dart';
import 'access_control/cosmos_db_permission.dart';
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
import 'queries/query.dart';

/// Class representing a CosmosDB container.
class CosmosDbContainer extends BaseDocument {
  CosmosDbContainer(this.database, this.id,
      {PartitionKeySpec? partitionKeySpec,
      IndexingPolicy? indexingPolicy,
      GeospatialConfig? geospatialConfig})
      : url = buildUrl(database.url, 'colls', id),
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
  /// this container-wide authorization.
  ///
  /// Note: calling this method overrides any previous authorization set via
  /// [useAuthorization] or [usePermission] or [grantAccess].
  @Deprecated('Use [grantAccess] instead.')
  void usePermission(CosmosDbPermission permission) {
    grantAccess(permission);
  }

  /// Clear the container-wide permission.
  ///
  /// Note: calling this method clears the underlying authorization, whether it
  /// was set from a permission via [usePermission] or from an authorization
  /// via [useAuthorization] or via [grantAccess].
  @Deprecated('Use [revokeAccess] instead.')
  void clearPermission() {
    revokeAccess();
  }

  /// Callback to refresh access control. This callback is called when a CosmosDB
  /// API call results in an access-control exception, typically:
  /// * an [UnauthorizedException] (HTTP error 401),
  /// * a [ForbiddenException] (HTTP error 403),
  /// * or an [InvalidTokenException] (HTTP error 498).
  /// and can be used to obtain a new access-control token such as a permission or
  /// an authorization.
  AccessControlAsyncCallback? refreshAccessControl;

  Future<CosmosDbAccessControl?> _refreshAccessControl([
    int? httpStatusCode,
    CosmosDbAccessControl? accessControl,
  ]) async {
    final ac = await refreshAccessControl?.call(httpStatusCode, accessControl);
    if (ac != null) {
      grantAccess(ac);
    }
    return ac;
  }

  /// Use this [CosmosDbAuthorization] when invoking the CosmosDB API. Using
  /// [CosmosDbAuthorization] is a way to avoid disclosing the master key in
  /// client applications; to retrieve or create an authorization, you should
  /// implement some additional API to be used by your client app. This API
  /// will protect your master keys. Most methods from [CosmosDbContainer]
  /// support an optional [authorization] argument, to allow for overriding
  /// this container-wide [authorization].
  ///
  /// Note: calling this method overrides any previous authorization set via
  /// [useAuthorization] or [usePermission] or [grantAccess].
  @Deprecated('Use [grantAccess] instead.')
  void useAuthorization(CosmosDbAuthorization authorization) {
    grantAccess(authorization);
  }

  /// Clear the container-wide authorization.
  ///
  /// Note: calling this method clears the underlying authorization, whether it
  /// was set from a permission via [usePermission] or from an authorization
  /// via [useAuthorization] or via [grantAccess].
  @Deprecated('Use [revokeAccess] instead.')
  void clearAuthorization() {
    revokeAccess();
  }

  /// Grant access to the resource using the associated access control token,
  /// eg. a [CosmosDbAuthorization] or a [CosmosDbPermission].
  void grantAccess(CosmosDbAccessControl accessControl) {
    _accessControl = accessControl;
  }

  /// Clear the container-wide access control.
  void revokeAccess() {
    _accessControl = null;
  }

  CosmosDbAccessControl? _accessControl;

  final _builders = <Type, DocumentBuilder>{};

  /// Register a [DocumentBuilder] for specified type `T`.
  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      _builders[T] = builder;

  /// Gets information for this [CosmosDbContainer].
  Future<CosmosDbContainer> getInfo(
      {CosmosDbAccessControl? accessControl}) async {
    final coll = await client.get<CosmosDbContainer>(
        url,
        Context(
          type: 'colls',
          accessControl: accessControl ?? _accessControl,
          throwOnNotFound: true,
          builder: database.containers.fromJson,
          refreshAccessControl: _refreshAccessControl,
        ));
    return coll!;
  }

  final _pkRanges = <PartitionKeyRange>[];

  /// Gets the partition key ranges for this [CosmosDbContainer].
  Future<Iterable<PartitionKeyRange>> getPkRanges(
      {CosmosDbAccessControl? accessControl, bool force = false}) async {
    if (_pkRanges.isEmpty || force) {
      _pkRanges.clear();
      _pkRanges.addAll(await client.getMany<PartitionKeyRange>(
          buildUrl(url, 'pkranges'),
          'PartitionKeyRanges',
          Context(
            resId: url,
            type: 'pkranges',
            accessControl: accessControl,
            throwOnNotFound: true,
            builder: PartitionKeyRange.fromJson,
            refreshAccessControl: _refreshAccessControl,
          )));
    }
    return _pkRanges;
  }

  /// Gets information for this [CosmosDbContainer].
  Future<void> setIndexingPolicy(IndexingPolicy indexingPolicy,
      {GeospatialConfig? geospatialConfig,
      CosmosDbAccessControl? accessControl}) async {
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
            accessControl: accessControl ?? _accessControl,
            builder: database.containers.fromJson,
            refreshAccessControl: _refreshAccessControl,
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
  Future<T?> find<T extends BaseDocument>(Object id, PartitionKey partitionKey,
          {bool throwOnNotFound = false,
          CosmosDbAccessControl? accessControl}) =>
      client.get<T>(
        buildUrl(url, 'docs', id.toString()),
        Context(
          type: 'docs',
          throwOnNotFound: throwOnNotFound,
          partitionKey: partitionKey,
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Returns the latest version of the document.
  Future<T?> get<T extends BaseDocument>(T document,
          {bool throwOnNotFound = false,
          PartitionKey? partitionKey,
          CosmosDbAccessControl? accessControl}) =>
      client
          .get<T>(
            buildUrl(url, 'docs', document.id.toString()),
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
              accessControl: accessControl ?? _accessControl,
              refreshAccessControl: _refreshAccessControl,
            ),
          )
          .onError<NotModifiedException>((error, stackTrace) => document);

  /// Lists all documents from this container.
  Future<Iterable<T>> list<T extends BaseDocument>(
          {PartitionKey? partitionKey, CosmosDbAccessControl? accessControl}) =>
      client.getMany<T>(
        buildUrl(url, 'docs'),
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          partitionKey: partitionKey ?? PartitionKey.all,
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Loads documents from this container matching the provided [query].
  Future<Iterable<T>> query<T extends BaseDocument>(Query query,
          {CosmosDbAccessControl? accessControl}) =>
      client.query<T>(
        buildUrl(url, 'docs'),
        query,
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          accessControl: accessControl ?? _accessControl,
          builders: _builders,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Loads documents from this container matching the provided [query].
  Future<dynamic> rawQuery(Query query,
          {CosmosDbAccessControl? accessControl}) =>
      client.rawQuery(
        buildUrl(url, 'docs'),
        query,
        'Documents',
        Context(
          type: 'docs',
          resId: url,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Adds a new [document] to this container.
  Future<T> add<T extends BaseDocument>(T document,
          {PartitionKey? partitionKey, CosmosDbAccessControl? accessControl}) =>
      client.post(
        buildUrl(url, 'docs'),
        document,
        Context(
          type: 'docs',
          resId: url,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Adds or updates (replaces) a [document] in this container.
  Future<T> upsert<T extends BaseDocument>(T document,
          {PartitionKey? partitionKey, CosmosDbAccessControl? accessControl}) =>
      client.post(
        buildUrl(url, 'docs'),
        document,
        Context(
          type: 'docs',
          resId: url,
          headers: HttpHeader.isUpsert,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Updates (replaces) a [document] in this container. If the [document] has
  /// [EtagMixin], its [EtagMixin.etag] must be known.
  Future<T> replace<T extends BaseDocument>(T document,
          {bool checkEtag = true,
          PartitionKey? partitionKey,
          CosmosDbAccessControl? accessControl}) =>
      client.put(
        buildUrl(url, 'docs', document.id.toString()),
        document,
        Context(
          type: 'docs',
          headers: (document is EtagMixin && checkEtag)
              ? {HttpHeader.ifMatch: document.etag}
              : null,
          partitionKey: partitionKey ?? partitionKeySpec.from(document),
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Updates (patches) a [document] in this container by applying the [patch]
  /// operations.
  Future<T> patch<T extends BaseDocument>(T document, Patch patch,
          {PartitionKey? partitionKey, CosmosDbAccessControl? accessControl}) =>
      client.patch(
        buildUrl(url, 'docs', document.id.toString()),
        patch,
        Context(
          type: 'docs',
          headers: HttpHeader.patchPayload,
          partitionKey: partitionKey ??
              partitionKeySpec.from(document) ??
              PartitionKey.all,
          builders: _builders,
          accessControl: accessControl ?? _accessControl,
          refreshAccessControl: _refreshAccessControl,
        ),
      );

  /// Deletes the document from this container. If the document does not exist,
  /// this method returns `true` by default. If [throwOnNotFound] is set to
  /// `true`, it will instead throw a [NotFoundException]. If the [document] is
  /// provided, its attributes take over the [id] value. If it has [EtagMixin],
  /// its [EtagMixin.etag] must be known.
  Future<bool> delete<T extends BaseDocument>(
      {Object? id,
      T? document,
      bool throwOnNotFound = false,
      bool checkEtag = true,
      PartitionKey? partitionKey,
      CosmosDbAccessControl? accessControl}) {
    if (document == null && id == null) {
      throw ApplicationException('Missing document and document id.');
    }
    id = document?.id ?? id;
    if (id == null) {
      throw ApplicationException('Missing document id');
    }
    return client.delete(
      buildUrl(url, 'docs', id.toString()),
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
        accessControl: accessControl ?? _accessControl,
        refreshAccessControl: _refreshAccessControl,
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
      {CosmosDbAccessControl? accessControl}) async {
    if (batch.operations.isEmpty) {
      return BatchResponse();
    } else {
      await getPkRanges(accessControl: accessControl);
      return await client.batch(
        buildUrl(url, 'docs'),
        batch,
        _pkRanges,
        Context(
          type: 'docs',
          resId: url,
          accessControl: accessControl ?? _accessControl,
          builders: _builders,
          refreshAccessControl: _refreshAccessControl,
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
