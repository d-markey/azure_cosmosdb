class PatchOperation {
  PatchOperation._(this.op, this.path, this.value);

  final String op;
  final String path;
  final dynamic value;

  PatchOperation.add(String path, dynamic value) : this._('add', path, value);
  PatchOperation.set(String path, dynamic value) : this._('set', path, value);
  PatchOperation.replace(String path, dynamic value)
      : this._('replace', path, value);
  PatchOperation.incr(String path, num value) : this._('incr', path, value);
  PatchOperation.decr(String path, num value) : this._('incr', path, -value);
  PatchOperation.remove(String path) : this._('remove', path, null);

  Map<String, dynamic> toJson() => {
        'op': op,
        'path': path,
        if (op != 'remove') 'value': value,
      };
}
