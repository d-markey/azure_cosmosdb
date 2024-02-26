import 'test_document.dart';

class TestTypedDocument extends TestDocument {
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
  int get hashCode => (id.hashCode << 2) ^ type.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! TestTypedDocument ||
        id != other.id ||
        type != other.type ||
        label != other.label ||
        data.length != other.data.length) {
      return false;
    }
    for (var i = 0; i < data.length; i++) {
      if (data[i] != other.data[i]) {
        return false;
      }
    }
    return true;
  }
}
