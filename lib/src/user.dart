import 'base_document.dart';

/// Class representing a CosmosDB user.
class User extends BaseDocumentWithEtag {
  User(this.id);

  @override
  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};

  /// Builds a [User] from a CosmosDB JSON object.
  static User build(Map json) {
    final user = User(json['id']);
    user.setEtag(json);
    return user;
  }
}
