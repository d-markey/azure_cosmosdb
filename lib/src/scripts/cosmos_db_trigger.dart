import '../base_document.dart';
import 'cosmos_db_script.dart';
import 'cosmos_db_trigger_operation.dart';
import 'cosmos_db_trigger_type.dart';

class CosmosDbTrigger extends CosmosDbScript {
  CosmosDbTrigger(String id, String body, this.type, this.operation)
      : super(id, body);

  final CosmosDbTriggerType type;
  final CosmosDbTriggerOperation operation;

  @override
  JSonMessage toJson() => super.toJson()
    ..addAll({
      'triggerType': type.name,
      'triggerOperation': operation.name,
    });
}
