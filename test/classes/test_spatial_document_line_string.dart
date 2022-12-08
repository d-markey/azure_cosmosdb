import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestSpatialDocumentLineString extends BaseDocumentWithEtag {
  TestSpatialDocumentLineString(this.id, this.from, this.to, this.path);

  @override
  final String id;

  String from;
  String to;
  final LineString path;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'f': from,
        't': to,
        'p': path.toGeoJson(),
      };

  static TestSpatialDocumentLineString fromJson(Map json) {
    final doc = TestSpatialDocumentLineString(
      json['id'],
      json['f'],
      json['t'],
      LineString.fromGeoJson(json['p'], GeospatialConfig.geography),
    );
    doc.setEtag(json);
    return doc;
  }
}
