import 'dart:io';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

import 'http_overrides.dart';
import 'to_do.dart';

// use the local CosmosDB Emulator
const cosmosDbUrl = 'https://localhost:8081/';
const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

void main() async {
  HttpOverrides.global = LocalhostHttpOverrides();
  // connect to the database, create it if necessary
  final cosmosDB = CosmosDbServer(cosmosDbUrl, masterKey: masterKey);
  final database = await cosmosDB.databases.openOrCreate(
    'ToDoDb',
    throughput: CosmosDbThroughput.minimum,
  );
  print('Database ready.');

  // open or create the container
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

  // register the builder for ToDo items
  todoCollection.registerBuilder<ToDo>(ToDo.fromJson);
  print('Container ready.');

  // create a new item and save it to Cosmos DB
  var today = DateTime.now();
  today = DateTime(today.year, today.month, today.day);
  final task = await todoCollection.add(ToDo(
    'Me',
    'Improve tests',
    dueDate: today.add(Duration(days: 3)),
  ));
  print('Added new task ${task.id} - ${task.label}');

  // query the collection
  final otherTasks = await todoCollection.query<ToDo>(
    Query('SELECT * FROM c WHERE c.id != @id', params: {'@id': task.id}),
  );

  if (otherTasks.isNotEmpty) {
    print('Other tasks:');
    for (var t in otherTasks) {
      var status = 'still pending';
      final dueDate = t.dueDate;
      if (t.completedDate != null) {
        status = 'done on ${t.completedDate}';
      } else if (dueDate != null) {
        if (dueDate == today) {
          status = 'expected today!';
        } else if (dueDate.isBefore(today)) {
          status = 'overdue since $dueDate';
        } else {
          status = 'expected for $dueDate';
        }
      }
      print('* ${t.id} - ${t.label} - $status');
    }
  }
}
