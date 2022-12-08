import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestSpatialDocumentPoint extends BaseDocumentWithEtag {
  TestSpatialDocumentPoint(this.id, this.label, this.location);

  @override
  final String id;

  String label;
  final Point location;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'p': location.toGeoJson(),
      };

  static TestSpatialDocumentPoint fromJson(Map json) {
    final doc = TestSpatialDocumentPoint(
      json['id'],
      json['l'],
      Point.fromGeoJson(json['p'], GeospatialConfig.geography),
    );
    doc.setEtag(json);
    return doc;
  }
}
