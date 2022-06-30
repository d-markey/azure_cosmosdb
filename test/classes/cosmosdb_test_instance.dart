import 'package:http/http.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;

import 'package:azure_cosmosdb/src/_debug_http_overrides_web.dart'
    if (dart.library.io) 'package:azure_cosmosdb/src/_debug_http_overrides_vm.dart'
    as debug;

const masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

void allowSelfSignedCertificates() => debug.allowSelfSignedCertificates();

cosmos_db.Instance getTestInstance(Client client) => cosmos_db.Instance(
      'https://localhost:8081',
      masterKey: masterKey,
      httpClient: client,
    );
