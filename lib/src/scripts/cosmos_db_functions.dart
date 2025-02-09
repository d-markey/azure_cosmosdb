part of 'cosmos_db_scripts.dart';

class CosmosDbFunctions extends _CosmosDbScripts<CosmosDbFunction> {
  CosmosDbFunctions(CosmosDbContainer container)
      : super(container, 'udfs', fromJson);

  @override
  final String _resultSet = 'UserDefinedFunctions';

  static CosmosDbFunction fromJson(JSonMessage json) => CosmosDbFunction(
        json['id'],
        json['body'],
      )..setEtag(json);
}
