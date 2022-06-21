import 'package:http/http.dart' as http;

import 'client.dart';
import 'databases.dart';

typedef FutureCallback<T> = Future<T> Function();

class Server {
  Server(String urlOrAccount, {String? masterKey, http.Client? httpClient})
      : client = Client(
          _buildUrl(urlOrAccount),
          masterKey: masterKey,
          httpClient: httpClient,
        );

  final Client client;

  late final Databases databases = Databases(client);

  static String _buildUrl(String url) {
    if (!url.contains('://')) url = 'https://$url.documents.azure.com/';
    if (!url.endsWith('/')) url += '/';
    return url;
  }
}
