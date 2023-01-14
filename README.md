[![Pub Package](https://badgen.net/pub/v/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)
[![Dart Platforms](https://badgen.net/pub/dart-platform/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)
[![Flutter Platforms](https://badgen.net/pub/flutter-platform/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)

[![License](https://img.shields.io/github/license/d-markey/azure_cosmosdb)](https://github.com/d-markey/azure_cosmosdb/blob/master/LICENSE)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Dart Style](https://img.shields.io/badge/style-lints-40c4ff)](https://pub.dev/packages/lints)
[![Pub Points](https://badgen.net/pub/points/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)
[![Likes](https://badgen.net/pub/likes/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)
[![Popularity](https://badgen.net/pub/popularity/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)

[![Last Commit](https://img.shields.io/github/last-commit/d-markey/azure_cosmosdb?logo=git&logoColor=white)](https://github.com/d-markey/azure_cosmosdb/commits)
[![Dart Workflow](https://github.com/d-markey/azure_cosmosdb/actions/workflows/dart.yml/badge.svg?logo=dart)](https://github.com/d-markey/azure_cosmosdb/actions/workflows/dart.yml)
[![Code Lines](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20lines&query=%24.linesValid&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fazure_cosmosdb%2Fmain%2Fcoverage.json)](https://github.com/d-markey/azure_cosmosdb/tree/main/coverage/html)
[![Code Coverage](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20coverage&query=%24.lineRate&suffix=%25&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fazure_cosmosdb%2Fmain%2Fcoverage.json)](https://github.com/d-markey/azure_cosmosdb/tree/main/coverage/html)

Connector for Azure Cosmos DB on Dart and Flutter platforms. Supports Cosmos DB SQL API, indexing policies, users, permissions, spatial types, batch operations, and hierarchical partition keys (preview/experimental).

## Table of Contents

* [Features](#features)
* [Getting Started](#started)
* [Connecting to a Cosmos DB Database](#connect)
* [Accessing a Cosmos DB Container](#containers)
* [Managing Documents in a Cosmos DB Container](#documents)
* [Batch Operations](#batch)
* [Users and Permissions](#permissions)
* [Disclaimer](#disclaimer)

## <a name="features"></a>Features

* `CosmosDbServer`: the main class used to communicate with your Azure Cosmos DB instance.
* `CosmosDbDatabase`: class representing an Azure Cosmos DB database hosted in `CosmosDbServer`.
* `CosmosDbContainer`: class representing an Azure Cosmos DB container from a `CosmosDbDatabase`.
* `BaseDocument`: class representing an Azure Cosmos DB document stored in a `CosmosDbContainer`.
* `Query`: class representing an Azure Cosmos DB SQL query to search documents in a `CosmosDbContainer`.
* `TransactionalBatch`: class containing a set of operations against documents in a `CosmosDbContainer`.
* `CosmosDbUsers` and `CosmosDbPermissions`: to manage users and rights in the Azure Cosmos DB database.

## <a name="started"></a>Getting Started

Import `azure_cosmosdb` from your `pubspec.yaml` file:

```yaml
dependencies:
   azure_cosmosdb: ^2.0.0
```

## <a name="connect"></a>Connecting to a Cosmos DB Database

Connections to Cosmos DB are managed via a `CosmosDbServer` instance, providing your Cosmos DB endpoint and master key (or permission). The `CosmosDbServer` instance provides methods to manage Cosmos DB databases via `CosmosDbServer.databases`.

For instance, to open or create a database:

```dart
  // connect to the database, create it if necessary
  final cosmosDB = CosmosDbServer('https://localhost:8081/', masterKey: '/* your master key*/');
  final database = await cosmosDB.databases.openOrCreate(
    'ToDoDb',
    throughput: CosmosDbThroughput.minimum,
  );
```

`CosmosDbServer` uses a default HTTP client and a default retry policy under the hood. A custom HTTP client and/or a custom retry policy may be provided when creating the `CosmosDbServer` object. For instance, `azure_cosmosdb` provides a debug HTTP client that can be used in test code or for debugging purposes.

For instance:

```dart
// DebugHttpClient is provided via the debug library
import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

final server = CosmosDbServer(
  'https://localhost:8081',
  masterKey: masterKey,
  httpClient: DebugHttpClient(),
);
```

## <a name="containers"></a>Accessing a Cosmos DB Container

Cosmos DB databases contain containers that are used to store documents. Cosmos DB containers are represented by `CosmosDbContainer` objects and managed via `CosmosDbDatabase.containers`.

For instance, to open or create a container in a database:

```dart
  // open or create a container with a specific indexing policy
  final indexingPolicy = IndexingPolicy(indexingMode: IndexingMode.consistent)
    ..excludedPaths.add(IndexPath('/*'))
    ..includedPaths.add(IndexPath('/"due-date"/?'))
    ..compositeIndexes.add([
      IndexPath('/label', order: IndexOrder.ascending),
      IndexPath('/"due-date"', order: IndexOrder.descending)
    ]);

  final todoCollection = await database.containers.openOrCreate(
    'todo_by_id',
    partitionKey: PartitionKeySpec.id,
    indexingPolicy: indexingPolicy,
  );
```

Data in containers is organized according to a partition key. `azure_cosmosdb` provides a built-in `PartitionKeySpec.id` (where the partition key is based on the `id` property), but custom partition keys may be specified when creating the container.

Data can also be indexed according to an indexing policy. By default, [Cosmos DB automatically indexes all document properties](https://learn.microsoft.com/en-us/azure/cosmos-db/index-policy).

## <a name="documents"></a>Managing Documents in a Cosmos DB Container

`azure_cosmosdb` provides base classes `BaseDocument` and `BaseDocumentWithEtag` to model the data you need to store in Azure Cosmos DB.

These base classes impement the `id` property as well as an abstract `toJson()` method returning a `Map<String, dynamic>` JSON object. Derived classes must provide the implementation for `toJson()` and must also implement a static `fromJson(Map json)` method to rebuild instances from the `Map` JSON objects returned by Azure Cosmos DB. Implementations can be manual or generated, e.g. via package [json_serializable](https://pub.dev/packages/json_serializable).

For instance:

```dart
class ToDo extends BaseDocumentWithEtag {
  ToDo._(
    this.id,
    this.label,
    this.description,
    this.dueDate,
    this.completedDate,
  );

  ToDo(
    String label, {
    String? description,
    DateTime? dueDate,
    DateTime? completedDate,
  }) : this._(autoId(), label, description, dueDate, completedDate);

  @override
  final String id;

  String label;
  String? description;
  DateTime? dueDate;
  DateTime? completedDate;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (description != null) 'description': description,
        'due-date': dueDate?.toUtc().toIso8601String(),
        'completed': completedDate?.toUtc().toIso8601String(),
      };

  static ToDo fromJson(Map json) {
    final todo = ToDo._(
      json['id'],
      json['label'],
      json['description'],
      DateTime.tryParse(json['due-date'] ?? '')?.toLocal(),
      DateTime.tryParse(json['completed'] ?? '')?.toLocal(),
    );
    todo.setEtag(json);
    return todo;
  }
}
```

The `CosmosDbContainer` class provides methods for CRUD operations (create/upsert, replace/update/patch, find and delete). It also provides the `CosmosDbContainer.query()` method to search for documents in Cosmos DB using SQL-like queries.

For instance:

```dart
  // register the builder for ToDo items
  todoCollection.registerBuilder<ToDo>(ToDo.fromJson);

  // create a new item and save it to Cosmos DB
  var today = DateTime.now();
  today = DateTime(today.year, today.month, today.day);
  final task = await todoCollection.add(ToDo(
    'Me',
    'Improve tests',
    dueDate: today.add(Duration(days: 3)),
  ));

  // query the collection
  final otherTasks = await todoCollection.query<ToDo>(
    Query('SELECT * FROM c WHERE c.id != @id', params: {'@id': task.id}),
  );
```

## <a name="batch"></a>Batch Operations

Batch operations on a container are supported via `CosmosDbContainer.prepareBatch()`. This method returns a `TransactionalBatch` object which will contain the individual operations to be executed. Operations are sent to Cosmos DB via `TransactionalBatch.execute()`.

Batch operations can be executed atomically where all operations succeed or all fail; this is controlled by the `isAtomic` parameter. By default, transactions are not atomic and can be configured to be "fault-tolerant" and continue executing after an error occured; this behavior is controlled by the `continueOnError` parameter.

Please note that operations in a `TransactionalBatch` must target documents sharing the same partition key. A `PartitionKeyException` will be thrown when calling `TransactionalBatch.execute()` if this is not the case.

For instance:

```dart
  // open or create the container
  final todoCollection = await database.containers.openOrCreate(
    'todo_by_owner',
    partitionKey: PartitionKeySpec('/owner'), // partition key based on the "owner" field
  );

  // register the builder for ToDo items
  todoCollection.registerBuilder<ToDo>(ToDo.fromJson);
  print('Container ready.');

  final teams = ['DevTeam1', 'DevTeam2', 'DevTeam3'];
  final owner = teams[rnd.nextInt(teams.length)];

  // create new items and batch-save them to Cosmos DB
  var today = DateTime.now();
  today = DateTime(today.year, today.month, today.day);
  final batch = todoCollection.prepareAtomicBatch();
  final count = 1 + rnd.nextInt(4);
  for (var i = 0; i < count; i++) {
    batch.create(ToDo(
      owner,
      getLabel(),
      dueDate: today.add(Duration(days: rnd.nextInt(5))),
    ));
  }
  final newTasks = await batch.execute();
```

## <a name="permissions"></a>Users and Permissions

Most APIs implemented in `azure_cosmosdb` support an optional `CosmosDbPermission` parameter
when calling Azure Cosmos DB.

This makes it possible to open a connection to Azure Cosmos DB without providing the master
key. The master key should be kept secret and should not be provided in Web apps or even
mobile apps.

Azure Cosmos DB manages a list of users and permissions at the database level. If you need
to implement direct access from a Web or mobile app to Azure Cosmos DB, you should create
a user for your app and grant permissions as necessary.

To retrieve the permission in your app, you should implement a REST API, e.g. an Azure
Function, that your app will call to get the required set of permissions. Only the REST
API will need to know the master key to retrieve the permissions.

## <a name="disclaimer"></a>Disclaimer

Please note that this library is not supported nor endorsed by Microsoft.
