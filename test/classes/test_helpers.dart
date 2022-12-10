import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

Future<CosmosDbServer?> getTestInstance() async {
  final server = CosmosDbServer(
    'https://localhost:8081',
    masterKey: masterKey,
    httpClient: DebugHttpClient(),
  )..disableLog();

  try {
    // make sure a CosmosDB instance is available for tests
    await server.databases.list();
    return server;
  } catch (ex) {
    test(
        '! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED - Exception ${ex.runtimeType}',
        () {});
    return null;
  }
}

int get millisecondsSinceEpoch => DateTime.now().millisecondsSinceEpoch;
int get secondsSinceEpoch => DateTime.now().millisecondsSinceEpoch ~/ 1000;

String getTempName([String? prefix]) =>
    '${prefix ?? 'temp'}_$millisecondsSinceEpoch';

extension LogExt on CosmosDbServer {
  // enabling logging is based on the `print`method
  void enableLog({bool withBody = true, bool withHeader = false}) =>
      useLogger(print, withBody: withBody, withHeader: withHeader);

  // disabling logging is actually done by using a silent logger and enabling
  // full tracing. This is done to cover the logging code during tests :)
  void disableLog() => useLogger(_noop, withBody: true, withHeader: true);

  static void _noop(dynamic print) {}
}
