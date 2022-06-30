import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

import 'classes/cosmosdb_test_instance.dart';

import 'test_suites/database_management.dart' as db_tests;
import 'test_suites/user_management.dart' as user_tests;
import 'test_suites/permission_management.dart' as permission_tests;
import 'test_suites/collection_management.dart' as coll_tests;
import 'test_suites/document_management.dart' as doc_tests;
import 'test_suites/document_queries.dart' as query_tests;

void main() async {
  allowSelfSignedCertificates();
  final httpClient = DebugHttpClient();
  final cosmosDB = getTestInstance(httpClient);

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  group('DATABASE MANAGEMENT -', () => db_tests.run(cosmosDB));

  group('USER MANAGEMENT -', () => user_tests.run(cosmosDB));

  group('PERMISSION MANAGEMENT -',
      () => permission_tests.run(cosmosDB, httpClient));

  group('COLLECTION MANAGEMENT -', () => coll_tests.run(cosmosDB));

  group('DOCUMENT MANAGEMENT -', () => doc_tests.run(cosmosDB));

  group('DOCUMENT QUERIES -', () => query_tests.run(cosmosDB, httpClient));
}
