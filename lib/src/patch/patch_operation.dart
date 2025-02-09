import '../base_document.dart';
import 'patch_operation_type.dart';

/// Class representing a patch operation.
class PatchOperation {
  PatchOperation._(this.type, this.path, this.value);

  /// The operation's [type].
  final PatchOperationType type;

  /// The target property [path].
  final String path;

  /// The [value] used to apply the operation..
  final dynamic value;

  /// Creates a new "[PatchOperationType.add]" patch operation.
  PatchOperation.add(String path, dynamic value)
      : this._(PatchOperationType.add, path, value);

  /// Creates a new "[PatchOperationType.set]" patch operation.
  PatchOperation.set(String path, dynamic value)
      : this._(PatchOperationType.set, path, value);

  /// Creates a new "[PatchOperationType.replace]" patch operation.
  PatchOperation.replace(String path, dynamic value)
      : this._(PatchOperationType.replace, path, value);

  /// Creates a new "[PatchOperationType.incr]" patch operation.
  PatchOperation.incr(String path, num value)
      : this._(PatchOperationType.incr, path, value);

  /// Creates a new "`PatchOperationType.decr`" patch operation. This is implemented
  /// as a "[PatchOperationType.incr]" operation with the opposite [value].
  PatchOperation.decr(String path, num value)
      : this._(PatchOperationType.incr, path, -value);

  /// Creates a new "[PatchOperationType.remove]" patch operation.
  PatchOperation.remove(String path)
      : this._(PatchOperationType.remove, path, null);

  /// Serializes this instance to a JSON object.
  JSonMessage toJson() => {
        'op': type.name,
        'path': path,
        if (type != PatchOperationType.remove) 'value': value,
      };
}
