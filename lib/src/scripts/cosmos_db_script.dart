import '../base_document.dart';

abstract class CosmosDbScript extends BaseDocumentWithEtag {
  CosmosDbScript(this.id, [String? body]) : _body = body;

  @override
  final String id;

  String get body => _body ?? '';
  String? _body;

  void setBody(String body) => _body = body;

  @override
  JSonMessage toJson() => {
        'id': id,
        if (_body != null) 'body': body,
        if (etag.isNotEmpty) '_etag': etag,
      };
}
