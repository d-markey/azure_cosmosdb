import '../cosmos_db_exceptions.dart';

/// Constants for permission modes.
class PermissionMode {
  const PermissionMode._(this.name);

  /// The [name] of this instance.
  final String name;

  /// `Read` permission.
  static const read = PermissionMode._('Read');

  /// `All` permission.
  static const all = PermissionMode._('All');

  /// `Opaque` permission: means the permission details are not known, eg. when
  /// a permission is created by a backend.
  static const opaque = PermissionMode._('Opaque');

  /// Returns the [PermissionMode] corresponding to [name].
  /// This method does not support the `BackendDriven`.
  static PermissionMode parse(String name) {
    if (name == read.name) return read;
    if (name == all.name) return all;
    throw BadResponseException('Unsupported permission mode.');
  }
}
