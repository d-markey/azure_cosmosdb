import 'dart:io';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

import 'http_overrides.dart';

// use the local CosmosDB Emulator
const cosmosDbUrl = 'https://localhost:8081/';
const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

void main() async {
  HttpOverrides.global = LocalhostHttpOverrides();
  final cosmosDB = CosmosDbServer(cosmosDbUrl, masterKey: masterKey);

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    print('Failed to reach Cosmos DB on $cosmosDbUrl!');
    return;
  }

  final database = await cosmosDB.databases.openOrCreate(
    'sample',
    throughput: CosmosDbThroughput.minimum,
  );

  final indexingPolicy =
      IndexingPolicy(indexingMode: IndexingMode.consistent, automatic: false);
  indexingPolicy.excludedPaths.add(IndexPath('/*'));
  indexingPolicy.includedPaths.add(IndexPath('/"due-date"/?'));
  indexingPolicy.compositeIndexes.add([
    IndexPath('/label', order: IndexOrder.ascending),
    IndexPath('/"due-date"', order: IndexOrder.descending)
  ]);

  final todoCollection = await database.collections.openOrCreate('todo',
      partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);

  todoCollection.registerBuilder<ToDo>(ToDo.build);

  try {
    final task = ToDo(
      'Improve tests',
      dueDate: DateTime.now().add(Duration(days: 3)),
    );

    final created = await todoCollection.add<ToDo>(task);

    print('Added new task ${task.id} - ${task.label}');
    print('Got task ${created.id} - ${created.label}');

    final tasks = await todoCollection.query<ToDo>(Query(
        'SELECT * FROM c WHERE c.label = @improvetests',
        params: {'@improvetests': task.label}));

    print('Other tasks:');
    for (var t in tasks.where((_) => _.id != task.id)) {
      String status = 'still pending';
      final dueDate = t.dueDate;
      if (t.done) {
        status = 'done';
      } else if (dueDate != null) {
        if (dueDate.isBefore(DateTime.now())) {
          status = 'overdue since $dueDate';
        } else {
          status = 'expected for $dueDate';
        }
      }
      print('* ${t.id} - ${t.label} - $status');
    }
  } on CosmosDbException catch (ex) {
    print(ex);
    print(ex.message);
    rethrow;
  }
}

class ToDo extends BaseDocumentWithEtag {
  ToDo(
    this.label, {
    String? id,
    this.description,
    this.dueDate,
    this.done = false,
  }) : // automatic id assignment for demo purposes
        // do not use this in production!
        id = id ?? 'demo_id_${DateTime.now().millisecondsSinceEpoch}';

  @override
  final String id;

  String label;
  String? description;
  DateTime? dueDate;
  bool done;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'due-date': dueDate?.toUtc().toIso8601String(),
        'done': done,
      };

  static ToDo build(Map json) {
    var dueDate = json['due-date'];
    if (dueDate != null) {
      dueDate = DateTime.parse(dueDate).toLocal();
    }
    final todo = ToDo(
      json['label'],
      id: json['id']!,
      description: json['description'],
      dueDate: dueDate,
      done: json['done'],
    );
    todo.setEtag(json);
    return todo;
  }
}
