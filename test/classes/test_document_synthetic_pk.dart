import 'test_document.dart';

class TestDocumentSyntheticPK extends TestDocument {
  TestDocumentSyntheticPK(String id, this.type, String label, List<int> data)
      : super(id, label, data);

  final String type;

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({'t': type, 'pk': syntheticKey});

  static TestDocumentSyntheticPK fromJson(Map json) {
    final doc = TestDocumentSyntheticPK(
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

  String get syntheticKey => '$id.$type';
}
