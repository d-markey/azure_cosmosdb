import 'base_document.dart';

class User extends BaseDocumentWithEtag {
  User(String id) : _id = id;

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> toJson() => {'id': _id};

  static User build(Map json) {
    final user = User(json['id']);
    user.setEtag(json);
    return user;
  }
}
