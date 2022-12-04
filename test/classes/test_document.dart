import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestDocument extends BaseDocumentWithEtag {
  TestDocument(this.id, this.label, this.data);

  @override
  final String id;

  String label;
  final List<int> data;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'd': data,
      };

  static TestDocument fromJson(Map json) {
    final doc = TestDocument(
      json['id'],
      json['l'],
      json['d'].cast<int>(),
    );
    doc.setEtag(json);
    return doc;
  }
}
