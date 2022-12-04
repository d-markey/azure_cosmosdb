import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

Future<CosmosDbServer?> getTestInstance() async {
  final server = CosmosDbServer(
    'https://localhost:8081',
    masterKey: masterKey,
    httpClient: DebugHttpClient(),
  );

  // enable logging to cover the logging code, but with a silent logger :)
  server.useSilentLogger();

  try {
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

String getTempDbName() => 'test_$millisecondsSinceEpoch';

extension LogExt on CosmosDbServer {
  void useSilentLogger() => useLogger((_) {}, withBody: true, withHeader: true);

  void useLogger(void Function(Object?) logger,
      {bool withBody = true, bool withHeader = false}) {
    final httpClient = dbgHttpClient;
    if (httpClient != null) {
      httpClient.log = logger;
      httpClient.trace = true;
      httpClient.traceBody = withBody;
      httpClient.traceHeaders = withHeader;
    }
  }
}
