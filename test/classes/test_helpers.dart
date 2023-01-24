import 'dart:async';
import 'dart:convert';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

Future<CosmosDbServer?> getTestInstance({required bool preview}) async {
  final server = CosmosDbServer(
    'https://localhost:8081',
    masterKey: masterKey,
    httpClient: DebugHttpClient(),
    preview: preview,
  );
  server.disableLog();

  try {
    // make sure a CosmosDB instance is available for tests
    await server.databases.list();
    return server;
  } catch (ex) {
    return null;
  }
}

int get secondsSinceEpoch => DateTime.now().millisecondsSinceEpoch ~/ 1000;

int _globalCounter = 0;

String getTempName([String? prefix]) {
  _globalCounter++;
  return '${prefix ?? 'temp'}_${_globalCounter}_$secondsSinceEpoch';
}

void checkDocument(BaseDocument doc, BaseDocument expected) => expect(
      jsonEncode(doc.toJson()),
      jsonEncode(expected.toJson()),
    );

extension LogExt on CosmosDbServer {
  // enabling logging is based on the `print`method
  void enableLog({bool withBody = true, bool withHeader = true}) =>
      useLogger(print, withBody: withBody, withHeader: withHeader);

  // disabling logging is actually done by using a silent logger and enabling
  // full tracing. This is done to cover the logging code during tests :)
  void disableLog() => useLogger(_noop, withBody: true, withHeader: true);

  static void _noop(dynamic print) {}
}
