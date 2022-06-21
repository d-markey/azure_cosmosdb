typedef DocumentBuilder<T extends BaseDocument> = T Function(Map json);

abstract class BaseDocument {
  String get id;
  Map<String, dynamic> toJson();
}

abstract class BaseDocumentWithEtag extends BaseDocument {
  String? _etag;
  String get etag => _etag ?? '';

  void setEtag(Map body) => _etag = body['_etag'];
}
