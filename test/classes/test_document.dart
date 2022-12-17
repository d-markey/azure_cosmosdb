import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestDocument extends BaseDocumentWithEtag {
  TestDocument(this.id, this.label, this.data);

  @override
  final String id;

  String label;
  final List<int> data;

  final props = <String, dynamic>{};

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'l': label,
        'd': data,
      }..addEntries(
          props.entries.where((element) => !element.key.startsWith(('_'))));

  static TestDocument fromJson(Map json) {
    final doc = TestDocument(
      json['id'],
      json['l'],
      json['d'].cast<int>(),
    );
    doc.setEtag(json);
    doc.props.addEntries(json.entries
        .map((e) => MapEntry(e.key.toString(), e.value))
        .where((e) => !const {'id', 'l', 'd', '_etag'}.contains(e.key)));
    return doc;
  }
}
