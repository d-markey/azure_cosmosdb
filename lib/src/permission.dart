import 'base_document.dart';

class Permission extends BaseDocumentWithEtag {
  Permission(this.id, this.mode, this.resource);

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'permissionMode': mode, 'resource': resource};

  static Permission build(Map json) {
    final permission =
        Permission(json['id'], json['permissionMode'], json['resource']);
    permission._token = json['_token'];
    permission.setEtag(json);
    return permission;
  }

  @override
  final String id;

  String mode;

  final String resource;

  String? _token;
  String get token => _token ?? '';

  void setToken(String token) {
    _token = token;
  }
}
