import 'package:http/http.dart' as http;

import 'impl/_client.dart';

import 'databases.dart';

typedef FutureCallback<T> = Future<T> Function();

/// Class representing a CosmosDB instance
class Instance {
  /// Builds a new Cosmos DB [Instance] with the provided [urlOrAccount], [masterKey] and
  /// [httpClient]. [urlOrAccount] can be a full URL (eg. `https://localhost:8081/`) or the
  /// Azure CosmosDB account name, in which case the url will be constructed as
  /// `https://${urlOrAccount}.documents.azure.com/`. Passing the [masterKey] is discouraged
  /// in client apps to prevent from theft; instead, a proxy should be implemented for client
  /// apps, especially Web apps, in order to protect the master key.
  Instance(String urlOrAccount, {String? masterKey, http.Client? httpClient})
      : _client = Client(
          _buildUrl(urlOrAccount),
          masterKey: masterKey,
          httpClient: httpClient,
        );

  final Client _client;

  /// Provides access to databases in this [Instance].
  late final Databases databases = Databases(this);

  static String _buildUrl(String url) {
    if (!url.contains('://')) url = 'https://$url.documents.azure.com/';
    if (!url.endsWith('/')) url += '/';
    return url;
  }
}

// internal use
extension InstanceExt on Instance {
  Client get client => _client;
}
