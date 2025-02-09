import '../base_document.dart';

/// Class representing a CosmosDB user.
class CosmosDbUser extends BaseDocument with EtagMixin {
  CosmosDbUser(this.id);

  @override
  final String id;

  @override
  JSonMessage toJson() => {'id': id};

  /// Builds a [CosmosDbUser] from a CosmosDB JSON object.
  static CosmosDbUser build(Map json) {
    final user = CosmosDbUser(json['id']);
    user.setEtag(json);
    return user;
  }
}
