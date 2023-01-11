import 'package:azure_cosmosdb/azure_cosmosdb.dart';

class TestDocumentMultiPK extends BaseDocument {
  TestDocumentMultiPK(this.id, this.tenantId, this.userId, this.label);

  @override
  final String id;

  final String tenantId;
  final String userId;
  String label;

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'tid': tenantId, 'uid': userId, 'l': label};

  static TestDocumentMultiPK fromJson(Map json) => TestDocumentMultiPK(
        json['id'],
        json['tid'],
        json['uid'],
        json['l'],
      );
}
