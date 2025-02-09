import '../base_document.dart';
import 'cosmos_db_script.dart';

class CosmosDbSproc extends CosmosDbScript {
  CosmosDbSproc(String id, String body) : super(id, body);
}

/// Base class for sproc calls.
class SprocArguments extends SpecialDocument {
  SprocArguments(this._arguments);

  final List<dynamic> _arguments;

  @override
  List<dynamic> toJson() => _arguments;
}
