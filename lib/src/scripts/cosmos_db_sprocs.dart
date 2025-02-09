part of 'cosmos_db_scripts.dart';

class CosmosDbSprocs extends _CosmosDbScripts<CosmosDbSproc> {
  CosmosDbSprocs(CosmosDbContainer container)
      : super(container, 'sprocs', fromJson);

  @override
  final String _resultSet = 'StoredProcedures';

  static CosmosDbSproc fromJson(JSonMessage json) => CosmosDbSproc(
        json['id'],
        json['body'],
      )..setEtag(json);
}
