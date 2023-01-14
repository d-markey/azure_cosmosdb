import 'dart:io';
import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

import 'http_overrides.dart';
import 'to_do.dart';

// use the local CosmosDB Emulator
const cosmosDbUrl = 'https://localhost:8081/';
const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

final rnd = Random();

void main() async {
  HttpOverrides.global = LocalhostHttpOverrides();
  // connect to the database, create it if necessary
  final cosmosDB = CosmosDbServer(cosmosDbUrl,
      masterKey: masterKey, httpClient: DebugHttpClient());
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
    'todo_by_owner',
    partitionKey: PartitionKeySpec('/owner'),
    indexingPolicy: indexingPolicy,
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

  print('New tasks for $owner:');
  for (var t in newTasks.results.map((r) => r.item as ToDo)) {
    print('* ${t.id} - ${t.owner} - ${t.label} - new');
  }

  // query the collection
  Iterable<ToDo> otherTeamTasks;
  // cosmosDB.useLogger(print, withHeader: true, withBody: true);
  // try {
  otherTeamTasks = await todoCollection.query<ToDo>(Query(
    'SELECT * FROM c WHERE NOT ARRAY_CONTAINS(@ids, c.id)',
    params: {'@ids': newTasks.results.map((r) => r.item!.id).toList()},
    partitionKey: PartitionKey(owner),
  ));
  // } finally {
  //   cosmosDB.resetLogger();
  // }

  print('Other $owner tasks:');
  for (var t in otherTeamTasks) {
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
    print('* ${t.id} - ${t.owner} - ${t.label} - $status');
  }

  // query the collection
  final allTasks = await todoCollection.query<ToDo>(Query(
    'SELECT * FROM c',
  ));

  print('All tasks:');
  for (var t in allTasks) {
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
    print('* ${t.id} - ${t.owner} - ${t.label} - $status');
  }
}

String getLabel() {
  final alphabet = {
    'a': 'ybcdfghjklmnpqrssttvwxz',
    'b': 'aaaeeeiiiooouuuyyybdlrr',
    'c': 'aaaeeeeiiiooouuycllrrt',
    'd': 'aaaeeeeiiiooouuyjmrrtv',
    'e': 'eeuybcddfghjkllmmnnppqrrssttvwxz',
    'f': 'aaaeeeeiiiooouuyfrrt',
    'g': 'aaaeeeeiiiooouuygmrr',
    'h': 'aaaeeeeiiiooouuyy',
    'i': 'aaeeoobcdfghjklmnpqrstvwxz',
    'j': 'aeiou',
    'k': 'aaaeeeeiiiooouuyllt',
    'l': 'aaaeeeeiiiooouuybcdfgkllmmnpqrsttv',
    'm': 'aaaeeeeiiiooouuybbmnpp',
    'n': 'aaaeeeeiiiooouuycddfggjklmnnqrrsttvvwxz',
    'o': 'ooybcdfghjkllmmnnpqrrssttvwxz',
    'p': 'aaaeeeeiiiooouuyhhllmprrst',
    'q': 'u',
    'r': 'aaaeeeeiiiooouuycdfghjklmnpqrstvwxz',
    's': 'aaaeeeeiiiooouuympsst',
    't': 'aaaeeeeiiiooouuyhmprrt',
    'u': 'eeeybcdfghjklmnpqrstvwxz',
    'v': 'aaaeeeeiiiooouuylr',
    'w': 'aaaeeeeiiiooouuy',
    'x': 'aaaeeeeiiiooouuytt',
    'y': 'aeoubcdfgklmnpqrstv',
    'z': 'aeiouy',
  };
  final words = 2 + rnd.nextInt(5);
  final sb = StringBuffer();
  for (var i = 0; i < words; i++) {
    var len = 1 + rnd.nextInt(13);
    if (i > 0) sb.write(' ');
    var letter = alphabet.entries.elementAt(rnd.nextInt(alphabet.length)).key;
    if (len == 1) {
      letter = 'aeiouy'[rnd.nextInt('aeiouy'.length)];
    }
    if (i == 0 || len > 2) {
      sb.write(letter.toUpperCase());
    } else {
      sb.write(letter);
    }
    for (var j = 1; j < len; j++) {
      letter = alphabet[letter]![rnd.nextInt(alphabet[letter]!.length)];
      sb.write(letter);
    }
  }
  return sb.toString();
}
