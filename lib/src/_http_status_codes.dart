abstract class HttpStatusCode {
  static const ok = 200;
  static const notFound = 404;
  static const unauthorized = 401;
  static const forbidden = 403;
  static const conflict = 409;
  static const serverError = 500;

  static bool success(int statusCode) => 200 <= statusCode && statusCode < 300;
}
