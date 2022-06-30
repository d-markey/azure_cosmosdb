import 'dart:io';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmosdb;

import 'http_overrides.dart';

const cosmosDbUrl = 'https://localhost:8081/';
const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

void main() async {
  HttpOverrides.global = LocalhostHttpOverrides();
  final cosmosDB = cosmosdb.Instance(cosmosDbUrl, masterKey: masterKey);

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    print('Failed to reach Cosmos DB on $cosmosDbUrl!');
    return;
  }

  final database = await cosmosDB.databases.openOrCreate('sample');
  final todoCollection =
      await database.collections.openOrCreate('todo', partitionKeys: ['/id']);

  todoCollection.registerBuilder<ToDo>(ToDo.build);

  final task = ToDo(
    DateTime.now().millisecondsSinceEpoch.toString(),
    'Improve tests',
    dueDate: DateTime.now().add(Duration(days: 3)),
  );

  await todoCollection.add(task);

  print('Added new task ${task.id} - ${task.label}');

  final tasks = await todoCollection.query<ToDo>(cosmosdb.Query(
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
}

class ToDo extends cosmosdb.BaseDocumentWithEtag {
  ToDo(
    this.id,
    this.label, {
    this.description,
    this.dueDate,
    this.done = false,
  });

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
      json['id'],
      json['label'],
      description: json['description'],
      dueDate: dueDate,
      done: json['done'],
    );
    todo.setEtag(json);
    return todo;
  }
}
