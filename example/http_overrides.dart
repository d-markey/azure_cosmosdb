import 'dart:io';

class LocalhostHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = handleBadCertificate;
    return client;
  }

  bool handleBadCertificate(X509Certificate cert, String host, int port) {
    return host.toLowerCase().contains('localhost') ||
        host.contains('127.0.0.1');
  }
}
