import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import 'classes/test_helpers.dart';

import 'test_suites/internal_helpers.dart' as internal_tests;
import 'test_suites/geometry_shapes.dart' as geometry_tests;
import 'test_suites/geography_shapes.dart' as geography_tests;
import 'test_suites/database_management.dart' as db_tests;
import 'test_suites/user_management.dart' as user_tests;
import 'test_suites/permission_management.dart' as permission_tests;
import 'test_suites/collection_management.dart' as coll_tests;
import 'test_suites/document_management.dart' as doc_tests;
import 'test_suites/document_queries.dart' as query_tests;
import 'test_suites/document_spatial.dart' as spatial_tests;

void main() async {
  final cosmosDB = await getTestInstance();

  group('INTERNAL HELPERS -', () => internal_tests.run());

  group('GEOMETRY SHAPES -', () => geometry_tests.run());

  group('GEOGRAPHY SHAPES -', () => geography_tests.run());

  if (cosmosDB != null) {
    group('DATABASE MANAGEMENT -', () => db_tests.run(cosmosDB));

    group('USER MANAGEMENT -', () => user_tests.run(cosmosDB));

    group('PERMISSION MANAGEMENT -', () => permission_tests.run(cosmosDB));

    group('COLLECTION MANAGEMENT -', () => coll_tests.run(cosmosDB));

    group('DOCUMENT MANAGEMENT -', () => doc_tests.run(cosmosDB));

    group('SPATIAL DOCUMENT -', () => spatial_tests.run(cosmosDB));

    group('DOCUMENT QUERIES -', () => query_tests.run(cosmosDB));

    test('Reset logger', () {
      cosmosDB.resetLogger();
      expect(cosmosDB.dbgHttpClient, isNotNull);
      expect(cosmosDB.dbgHttpClient!.log, equals(DebugHttpClient.defaultLog));
      expect(cosmosDB.dbgHttpClient!.trace, isFalse);
      expect(cosmosDB.dbgHttpClient!.traceHeaders, isFalse);
      expect(cosmosDB.dbgHttpClient!.traceBody, isFalse);
    });
  }
}
