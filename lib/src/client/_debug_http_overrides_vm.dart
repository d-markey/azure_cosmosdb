import 'dart:developer';
import 'dart:io';

class LocalhostHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = handleBadCertificate;
    return client;
  }

  static bool handleBadCertificate(
      X509Certificate cert, String host, int port) {
    final ok = host.toLowerCase().contains('localhost') ||
        host.contains('127.0.0.1') ||
        host.contains('::1') ||
        host.contains('0:0:0:0:0:0:0:1');
    log('Bad certificate from $host: ${ok ? 'bypass security' : 'enforce security'}');
    return ok;
  }
}

var _installed = false;

void allowSelfSignedCertificates() {
  if (!_installed) {
    _installed == true;
    HttpOverrides.global = LocalhostHttpOverrides();
  }
}
