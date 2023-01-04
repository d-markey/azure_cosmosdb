import 'package:azure_cosmosdb/azure_cosmosdb.dart';

import 'test_document.dart';

class TestTypedDocument extends TestDocument with PartitionKeyMixin {
  TestTypedDocument(String id, this.type, String label, List<int> data)
      : super(id, label, data);

  final String type;

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'t': type});

  static TestTypedDocument fromJson(Map json) {
    final doc = TestTypedDocument(
      json['id'],
      json['t'],
      json['l'],
      json['d'].cast<int>(),
    );
    doc.setEtag(json);
    doc.props.addEntries(json.entries
        .map((e) => MapEntry(e.key.toString(), e.value))
        .where((e) => !const {'id', 't', 'l', 'd', '_etag'}.contains(e.key)));
    return doc;
  }

  @override
  List<String> get keys => [type];
}
