part of 'cosmos_db_scripts.dart';

class CosmosDbTriggers extends _CosmosDbScripts<CosmosDbTrigger> {
  CosmosDbTriggers(CosmosDbContainer container)
      : super(container, 'triggers', fromJson);

  @override
  final String _resultSet = 'Triggers';

  static CosmosDbTrigger fromJson(JSonMessage json) => CosmosDbTrigger(
        json['id'],
        json['body'],
        CosmosDbTriggerType.tryParse(json['triggerType'])!,
        CosmosDbTriggerOperation.tryParse(json['triggerOperation'])!,
      )..setEtag(json);
}
