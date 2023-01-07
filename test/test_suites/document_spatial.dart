import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/spatial_data_sets.dart';
import '../classes/test_helpers.dart';
import '../classes/test_spatial_document_line_string.dart';
import '../classes/test_spatial_document_multi_polygon.dart';
import '../classes/test_spatial_document_polygon.dart';
import '../classes/test_spatial_document_point.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbContainer container;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes
        .add(SpatialIndexPath('/p/?', types: [DataType.point]));
    container = await database.containers.create('items',
        partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);
    container.registerBuilder<TestSpatialDocumentPoint>(
        TestSpatialDocumentPoint.fromJson);
    container.registerBuilder<TestSpatialDocumentLineString>(
        TestSpatialDocumentLineString.fromJson);
    container.registerBuilder<TestSpatialDocumentPolygon>(
        TestSpatialDocumentPolygon.fromJson);
    container.registerBuilder<TestSpatialDocumentMultiPolygon>(
        TestSpatialDocumentMultiPolygon.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('Add documents - Points', () async {
    var doc = await container.add(TestSpatialDocumentPoint(
        '1', 'Eiffel Tower (Paris)', monuments['Eiffel Tower']!));
    expect(doc.label, contains('Eiffel Tower'));
    doc = await container.add(TestSpatialDocumentPoint(
        '2', 'Big Ben (London)', monuments['Big Ben']!));
    expect(doc.label, contains('Big Ben'));
  });

  test('Add documents - Lines', () async {
    var doc = await container.add(TestSpatialDocumentLineString(
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
    var doc = await container
        .add(TestSpatialDocumentPolygon('Paris', 'Paris Area', parisArea));
    expect(doc.label, equals('Paris Area'));
  });

  test('Add documents - MultiPolygon', () async {
    var doc = await container.add(TestSpatialDocumentMultiPolygon(
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
