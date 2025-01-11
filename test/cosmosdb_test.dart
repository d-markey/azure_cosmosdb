import 'dart:developer';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import 'classes/test_helpers.dart';
import 'test_suites/container_management.dart' as container_tests;
import 'test_suites/database_management.dart' as db_tests;
import 'test_suites/document_batch.dart' as batch_tests;
import 'test_suites/document_management.dart' as doc_tests;
import 'test_suites/document_queries.dart' as query_tests;
import 'test_suites/document_spatial.dart' as spatial_tests;
import 'test_suites/expression_tokenizer.dart' as tokenizer_tests;
import 'test_suites/geography_shapes.dart' as geography_tests;
import 'test_suites/geometry_shapes.dart' as geometry_tests;
import 'test_suites/internal_helpers.dart' as internal_tests;
import 'test_suites/partition_keys.dart' as pk_tests;
import 'test_suites/path_parser.dart' as path_parser_tests;
import 'test_suites/permission_management.dart' as permission_tests;
import 'test_suites/user_management.dart' as user_tests;

void main() async {
  log('AZURE_COSMOSDB - Start Tests...');

  group('INTERNAL HELPERS -', () => internal_tests.run());

  group('EXPRESSION TOKENIZER -', () => tokenizer_tests.run());

  group('GEOMETRY SHAPES -', () => geometry_tests.run());

  group('GEOGRAPHY SHAPES -', () => geography_tests.run());

  group('PATH PARSER -', () => path_parser_tests.run());

  group('PARTITION KEYS -', () => pk_tests.run());

  final currentCosmosDb = await getTestInstance(preview: false);
  final previewCosmosDb = await getTestInstance(preview: true);

  group('CURRENT -', () => runCosmosDbTests(currentCosmosDb));

  group('PREVIEW -', () => runCosmosDbTests(previewCosmosDb));
}

void runCosmosDbTests(CosmosDbServer? cosmosDb) {
  test('COSMOS DB CONNECTION', () {
    expect(cosmosDb, isNotNull);
  });

  if (cosmosDb != null) {
    group('DATABASE MANAGEMENT -', () => db_tests.run(cosmosDb));

    group('USER MANAGEMENT -', () => user_tests.run(cosmosDb));

    group('PERMISSION MANAGEMENT -', () => permission_tests.run(cosmosDb));

    group('CONTAINER MANAGEMENT -', () => container_tests.run(cosmosDb));

    group('DOCUMENT MANAGEMENT -', () => doc_tests.run(cosmosDb));

    group('SPATIAL DOCUMENT -', () => spatial_tests.run(cosmosDb));

    group('DOCUMENT QUERIES -', () => query_tests.run(cosmosDb));

    group('DOCUMENT BATCHES -', () => batch_tests.run(cosmosDb));

    test('LOGGER - Reset logger', () {
      expect(cosmosDb.dbgHttpClient, isNotNull);

      cosmosDb.enableLog(withBody: false, withHeader: true);
      expect(cosmosDb.dbgHttpClient!.log, equals(print));
      expect(cosmosDb.dbgHttpClient!.trace, isTrue);
      expect(cosmosDb.dbgHttpClient!.traceHeaders, isTrue);
      expect(cosmosDb.dbgHttpClient!.traceBody, isFalse);

      cosmosDb.resetLogger();
      expect(cosmosDb.dbgHttpClient!.log, equals(DebugHttpClient.defaultLog));
      expect(cosmosDb.dbgHttpClient!.trace, isFalse);
      expect(cosmosDb.dbgHttpClient!.traceHeaders, isFalse);
      expect(cosmosDb.dbgHttpClient!.traceBody, isFalse);
    });
  }
}
