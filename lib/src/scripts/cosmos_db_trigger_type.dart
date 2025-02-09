class CosmosDbTriggerType {
  const CosmosDbTriggerType._(this.name);

  final String name;

  static const pre = CosmosDbTriggerType._('Pre');
  static const post = CosmosDbTriggerType._('Post');

  static final _values = {pre.name: pre, post.name: post};

  static CosmosDbTriggerType? tryParse(String? type) => _values[type];
}
