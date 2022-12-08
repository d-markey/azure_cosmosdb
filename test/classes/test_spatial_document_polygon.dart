import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestSpatialDocumentPolygon extends BaseDocumentWithEtag {
  TestSpatialDocumentPolygon(this.id, this.label, this.area);

  @override
  final String id;

  String label;
  final Polygon area;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'a': area.toGeoJson(),
      };

  static TestSpatialDocumentPolygon fromJson(Map json) {
    final doc = TestSpatialDocumentPolygon(
      json['id'],
      json['l'],
      Polygon.fromGeoJson(json['a'], GeospatialConfig.geography),
    );
    doc.setEtag(json);
    return doc;
  }
}
