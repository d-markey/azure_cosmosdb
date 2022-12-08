import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestSpatialDocumentMultiPolygon extends BaseDocumentWithEtag {
  TestSpatialDocumentMultiPolygon(this.id, this.label, this.areas);

  @override
  final String id;

  String label;
  final MultiPolygon areas;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'a': areas.toGeoJson(),
      };

  static TestSpatialDocumentMultiPolygon fromJson(Map json) {
    final doc = TestSpatialDocumentMultiPolygon(
      json['id'],
      json['l'],
      MultiPolygon.fromGeoJson(json['a'], GeospatialConfig.geography),
    );
    doc.setEtag(json);
    return doc;
  }
}
