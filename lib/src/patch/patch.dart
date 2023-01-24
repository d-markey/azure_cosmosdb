import '../base_document.dart';
import '_token.dart';
import '_tokenizer.dart';
import 'patch_operation.dart';

/// Class representing a series of operations to modify a document.
class Patch extends SpecialDocument {
  String? _condition;
  final _ops = <PatchOperation>[];
  Map<String, dynamic>? _parameters;

  /// Sets the [condition] to decide whether this patch should be applied to
  /// the target document.
  void setCondition(String condition) => _condition = condition;

  /// Registers a parameter's value, used in the patch's condition.
  void withParam(String name, dynamic value) =>
      (_parameters ??= {})[name] = value;

  /// Rewrites the condition, replacing parameters with their values.
  String _getCondition() {
    var cond = _condition!;
    if (_parameters != null) {
      final parser = Tokenizer(cond);
      final parts = <String>[];
      var needSpace = false;
      for (var token in parser.getTokens(_parameters)) {
        switch (token.type) {
          case Token.parameterValue:
          case Token.identifier:
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            needSpace = true;
            break;
          case Token.number:
          case Token.string:
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            needSpace = true;
            break;
          case Token.separator:
            if (token.text == ':') {
              parts.add(' ');
            }
            parts.add(token.text);
            needSpace = (token.text == ',' || token.text == ':');
            break;
          case Token.operator:
            needSpace = (token.text != '.');
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            break;
        }
      }
      cond = parts.join();
    }
    return cond;
  }

  /// Adds a property identified by [path] with [value] to the target document.
  void add(String path, dynamic value) =>
      _ops.add(PatchOperation.add(path, value));

  /// Sets the property identified by [path] with [value] in the target document.
  void set(String path, dynamic value) =>
      _ops.add(PatchOperation.set(path, value));

  /// Replaces the property identified by [path] with [value] in the target document.
  void replace(String path, dynamic value) =>
      _ops.add(PatchOperation.replace(path, value));

  /// Increments the property identified by [path] by [value] in the target document.
  void increment(String path, [num value = 1]) =>
      _ops.add(PatchOperation.incr(path, value));

  /// Decrements the property identified by [path] by [value] in the target document.
  void decrement(String path, [num value = 1]) =>
      _ops.add(PatchOperation.decr(path, value));

  /// Removes the property identified by [path] from the target document.
  void remove(String path) => _ops.add(PatchOperation.remove(path));

  @override
  Map<String, dynamic> toJson() => {
        if (_condition != null) 'condition': _getCondition(),
        'operations': _ops.map((o) => o.toJson()).toList(),
      };
}
