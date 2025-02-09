class CosmosDbTriggerOperation {
  const CosmosDbTriggerOperation._(this.name);

  final String name;

  static const all = CosmosDbTriggerOperation._('All');
  static const create = CosmosDbTriggerOperation._('Create');
  static const delete = CosmosDbTriggerOperation._('Delete');
  static const replace = CosmosDbTriggerOperation._('Replace');

  static final _values = {
    all.name: all,
    create.name: create,
    delete.name: delete,
    replace.name: replace
  };

  static CosmosDbTriggerOperation? tryParse(String? operation) =>
      _values[operation];
}
