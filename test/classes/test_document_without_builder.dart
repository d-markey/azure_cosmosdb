import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestDocumentWithoutBuilder extends BaseDocumentWithEtag {
  TestDocumentWithoutBuilder(this.id, this.label, this.data);

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
}
