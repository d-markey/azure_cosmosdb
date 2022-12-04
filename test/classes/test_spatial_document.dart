import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestSpatialDocument extends BaseDocumentWithEtag {
  TestSpatialDocument(this.id, this.label, this.location);

  @override
  final String id;

  String label;
  final Point location;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'p': location.toJson(),
      };

  static TestSpatialDocument fromJson(Map json) {
    final p = json['p'];
    final coords = p['coordinates'];
    if (p['type'].toString().toLowerCase() !=
            DataType.point.name.toLowerCase() ||
        coords is! List ||
        coords.length != 2) {
      throw BadResponseException('Unexpected location type');
    }
    final location = Point.geography(coords[0], coords[1]);
    final doc = TestSpatialDocument(
      json['id'],
      json['l'],
      location,
    );
    doc.setEtag(json);
    return doc;
  }
}
