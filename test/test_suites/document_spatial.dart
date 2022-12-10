import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/spatial_data_sets.dart';
import '../classes/test_helpers.dart';
import '../classes/test_spatial_document_line_string.dart';
import '../classes/test_spatial_document_multi_polygon.dart';
import '../classes/test_spatial_document_polygon.dart';
import '../classes/test_spatial_document_point.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbCollection collection;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes
        .add(SpatialIndexPath('/p/?', types: [DataType.point]));
    collection = await database.collections.create('items',
        partitionKeys: ['/id'], indexingPolicy: indexingPolicy);
    collection.registerBuilder<TestSpatialDocumentPoint>(
        TestSpatialDocumentPoint.fromJson);
    collection.registerBuilder<TestSpatialDocumentLineString>(
        TestSpatialDocumentLineString.fromJson);
    collection.registerBuilder<TestSpatialDocumentPolygon>(
        TestSpatialDocumentPolygon.fromJson);
    collection.registerBuilder<TestSpatialDocumentMultiPolygon>(
        TestSpatialDocumentMultiPolygon.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('Add documents - Points', () async {
    var doc = await collection.add(TestSpatialDocumentPoint(
        '1', 'Eiffel Tower (Paris)', monuments['Eiffel Tower']!));
    expect(doc.label, contains('Eiffel Tower'));
    doc = await collection.add(TestSpatialDocumentPoint(
        '2', 'Big Ben (London)', monuments['Big Ben']!));
    expect(doc.label, contains('Big Ben'));
  });

  test('Add documents - Lines', () async {
    var doc = await collection.add(TestSpatialDocumentLineString(
        'Paris-London',
        'Paris',
        'London',
        LineString()
          ..addAll([
            cities['Paris']!,
            cities['London']!,
          ])));
    expect(doc.from, equals('Paris'));
    expect(doc.to, equals('London'));
  });

  test('Add documents - Polygon', () async {
    var doc = await collection
        .add(TestSpatialDocumentPolygon('Paris', 'Paris Area', parisArea));
    expect(doc.label, equals('Paris Area'));
  });

  test('Add documents - MultiPolygon', () async {
    var doc = await collection.add(TestSpatialDocumentMultiPolygon(
        'ParisBois',
        'Bois de Paris',
        MultiPolygon()
          ..addAll([
            boisDeBoulogneArea,
            boisDeVincennesArea,
          ])));
    expect(doc.label, equals('Bois de Paris'));
  });
}
