import '../base_document.dart';

@Deprecated('Use CosmosDbUser instead.')
typedef User = CosmosDbUser;

/// Class representing a CosmosDB user.
class CosmosDbUser extends BaseDocumentWithEtag {
  CosmosDbUser(this.id);

  @override
  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};

  /// Builds a [CosmosDbUser] from a CosmosDB JSON object.
  static CosmosDbUser build(Map json) {
    final user = CosmosDbUser(json['id']);
    user.setEtag(json);
    return user;
  }
}
