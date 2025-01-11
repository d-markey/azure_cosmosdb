import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import 'authorizations/cosmos_db_authorization.dart';
import 'client/_client.dart';
import 'client/debug_http_client.dart';
import 'client/features.dart';
import 'cosmos_db_databases.dart';

typedef AsyncCallback<T> = Future<T> Function([
  int? httpStatusCode,
  CosmosDbAuthorization? auth,
]);

/// Class representing a CosmosDB instance.
class CosmosDbServer {
  /// Builds a new Cosmos DB [CosmosDbServer] with the provided [urlOrAccount],
  /// [masterKey] and [httpClient]. [urlOrAccount] can be a full URL (eg.
  /// `https://localhost:8081/`) or the Azure CosmosDB account name, in which case
  /// the url will be constructed as `https://${urlOrAccount}.documents.azure.com/`.
  /// Passing the [masterKey] is discouraged in client apps to prevent from theft;
  /// instead, a proxy should be implemented in order to protect the master key.
  CosmosDbServer(String urlOrAccount,
      {String? masterKey,
      http.Client? httpClient,
      RetryOptions? retryOptions,
      bool multipleWriteLocations = false,
      bool preview = false})
      : _client = Client(
          _buildUrl(urlOrAccount),
          masterKey: masterKey,
          httpClient: httpClient,
          retryOptions: retryOptions,
          multipleWriteLocations: multipleWriteLocations,
          version: preview ? previewApiVersion : currentApiVersion,
        );

  final Client _client;

  /// Provides access to databases in this [CosmosDbServer].
  late final CosmosDbDatabases databases = CosmosDbDatabases(this);

  String get version => _client.version;

  Features get features => _client.features;

  static String _buildUrl(String urlOrAccount) => !urlOrAccount.contains('://')
      ? 'https://$urlOrAccount.documents.azure.com/'
      : !urlOrAccount.endsWith('/')
          ? '$urlOrAccount/'
          : urlOrAccount;
}

// debug use
extension CosmosDbServerDbgExt on CosmosDbServer {
  /// The underlying HTTP client used to communicate with the Cosmos DB server.
  DebugHttpClient? get dbgHttpClient {
    final client = _client.httpClient;
    return (client is DebugHttpClient) ? client : null;
  }

  /// Activate a logger. Typically used with a `try`/`finally` block, e.g.:
  /// ```dart
  /// server.useLogger(print);
  /// try {
  ///   // do something eg. create a container, add a document, execute a query...
  ///   // the request to CosmosDB will be logged
  /// } finally {
  ///   server.resetLogger();
  /// }
  /// ```
  void useLogger(void Function(Object?) logger,
      {bool withBody = false, bool withHeader = false}) {
    final dbgClient = dbgHttpClient;
    if (dbgClient != null) {
      dbgClient.log = logger;
      dbgClient.trace = true;
      dbgClient.traceBody = withBody;
      dbgClient.traceHeaders = withHeader;
    }
  }

  /// Reset the logger.
  void resetLogger() {
    final dbgClient = dbgHttpClient;
    if (dbgClient != null) {
      dbgClient.log = DebugHttpClient.defaultLog;
      dbgClient.trace = false;
      dbgClient.traceBody = false;
      dbgClient.traceHeaders = false;
    }
  }
}

// internal use
@internal
extension CosmosDbServerInternalExt on CosmosDbServer {
  /// The CosmosDB client used for this instance.
  Client get client => _client;
}
