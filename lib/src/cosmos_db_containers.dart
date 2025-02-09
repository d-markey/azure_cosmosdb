import '_internal/_extensions.dart';
import 'access_control/cosmos_db_access_control.dart';
import 'client/_context.dart';
import 'conflicts/conflict_resolution_policy.dart';
import 'cosmos_db_container.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_throughput.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'partition/partition_key_spec.dart';

/// Class used to manage [CosmosDbContainer]s in a [CosmosDbDatabase].
class CosmosDbContainers {
  CosmosDbContainers(this.database) : url = '${database.url}/colls';

  /// The [CosmosDbDatabase] this container belongs to.
  final CosmosDbDatabase database;

  /// The container's [url].
  final String url;

  /// Deserialize data from JSON object [json] into a new [CosmosDbContainer] instance.
  /// Handles fields `id`, `partitionKey`, `indexingPolicy`.
  CosmosDbContainer fromJson(Map json) => CosmosDbContainer(
        database,
        json['id'],
        partitionKeySpec: PartitionKeySpec.fromJson(json['partitionKey']),
        indexingPolicy: IndexingPolicy.fromJson(json['indexingPolicy']),
        conflictResolutionPolicy:
            ConflictResolutionPolicy.fromJson(json['conflictResolutionPolicy']),
        defaultTtl: json['defaultTtl'],
        analyticalStorageTtl: json['analyticalStorageTtl'],
      )..setExists(true);

  /// Lists all containers from this [database].
  Future<Iterable<CosmosDbContainer>> list(
          {CosmosDbAccessControl? accessControl}) =>
      database.client.getMany<CosmosDbContainer>(
        url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: fromJson,
          accessControl: accessControl,
        ),
      );

  /// Deletes the specified [container] from this [database]. All documents in this
  /// [container] will be lost. If the [container] does not exists, this method
  /// returns `true` by default. if [throwOnNotFound] is set to `true`, it will throw
  /// a [NotFoundException] instead. Upon success, the [CosmosDbContainer.exists] flag will
  /// be set to `false`.
  Future<bool> delete(CosmosDbContainer container,
          {bool throwOnNotFound = false,
          CosmosDbAccessControl? accessControl}) =>
      database.client
          .delete(
        buildUrl(url, container.id),
        Context(
          type: 'colls',
          throwOnNotFound: throwOnNotFound,
          accessControl: accessControl,
        ),
      )
          .then((value) {
        container.setExists(false);
        return true;
      });

  /// Creates a new [CosmosDbContainer] with the specified `name` and `partitionKeys`.
  Future<CosmosDbContainer> create(
    String name, {
    required PartitionKeySpec partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    int? defaultTtl,
    int? analyticalStorageTtl,
    CosmosDbAccessControl? accessControl,
    CosmosDbThroughput? throughput,
  }) =>
      database.client.post<CosmosDbContainer>(
        url,
        CosmosDbContainer(
          database,
          name,
          partitionKeySpec: partitionKey,
          indexingPolicy: indexingPolicy,
          geospatialConfig: geospatialConfig,
          defaultTtl: defaultTtl,
          analyticalStorageTtl: analyticalStorageTtl,
        ),
        Context(
          type: 'colls',
          resId: database.url,
          headers: (throughput ?? CosmosDbThroughput.minimum).header,
          accessControl: accessControl,
          builder: fromJson,
        ),
      );

  /// Opens an existing [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> open(
    String name, {
    CosmosDbAccessControl? accessControl,
  }) =>
      CosmosDbContainer(database, name).getInfo(accessControl: accessControl);

  /// Opens or creates a [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> openOrCreate(
    String name, {
    PartitionKeySpec? partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    int? defaultTtl,
    int? analyticalStorageTtl,
    CosmosDbThroughput? throughput,
    CosmosDbAccessControl? accessControl,
  }) async {
    try {
      return await open(
        name,
        accessControl: accessControl,
      );
    } on NotFoundException {
      if (partitionKey == null) {
        throw ApplicationException(
            'Container \'$name\' not found - can not create with a null partion key');
      }
      return await create(
        name,
        partitionKey: partitionKey,
        indexingPolicy: indexingPolicy,
        geospatialConfig: geospatialConfig,
        defaultTtl: defaultTtl,
        analyticalStorageTtl: analyticalStorageTtl,
        throughput: throughput,
        accessControl: accessControl,
      );
    }
  }
}
