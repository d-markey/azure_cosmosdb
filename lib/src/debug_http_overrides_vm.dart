import 'dart:developer' as dev;
import 'dart:io';

class LocalhostHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = handleBadCertificate;
    return client;
  }

  bool handleBadCertificate(X509Certificate cert, String host, int port) {
    dev.log('Bad certificate from $host');
    return host.toLowerCase().contains('localhost') ||
        host.contains('127.0.0.1');
  }
}

var _installed = false;

void allowSelfSignedCertificates() {
  if (!_installed) {
    HttpOverrides.global = LocalhostHttpOverrides();
    dev.log('LocalhostHttpOverrides installed');
  }
}
