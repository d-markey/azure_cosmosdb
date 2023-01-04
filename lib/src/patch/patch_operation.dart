class PatchOperationType {
  const PatchOperationType._(this.name);

  final String name;

  static const add = PatchOperationType._('add');
  static const set = PatchOperationType._('set');
  static const replace = PatchOperationType._('replace');
  static const remove = PatchOperationType._('remove');
  static const incr = PatchOperationType._('incr');
}

class PatchOperation {
  PatchOperation._(this.op, this.path, this.value);

  final PatchOperationType op;
  final String path;
  final dynamic value;

  PatchOperation.add(String path, dynamic value)
      : this._(PatchOperationType.add, path, value);
  PatchOperation.set(String path, dynamic value)
      : this._(PatchOperationType.set, path, value);
  PatchOperation.replace(String path, dynamic value)
      : this._(PatchOperationType.replace, path, value);
  PatchOperation.incr(String path, num value)
      : this._(PatchOperationType.incr, path, value);
  PatchOperation.decr(String path, num value)
      : this._(PatchOperationType.incr, path, -value);
  PatchOperation.remove(String path)
      : this._(PatchOperationType.remove, path, null);

  Map<String, dynamic> toJson() => {
        'op': op.name,
        'path': path,
        if (op != PatchOperationType.remove) 'value': value,
      };
}
