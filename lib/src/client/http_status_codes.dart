/// Constants for HTTP status codes.
abstract class HttpStatusCode {
  static const ok = 200;
  static const created = 201;
  static const noContent = 204;
  static const notModified = 304;
  static const badRequest = 400;
  static const unauthorized = 401;
  static const forbidden = 403;
  static const notFound = 404;
  static const conflict = 409;
  static const preconditionFailure = 412;
  static const failedDependency = 424;
  static const tooManyRequests = 429;
  static const serverError = 500;
  static const serviceUnavailable = 503;

  /// Returns `true` if [code] is in the range 200-299, `false` otherwise.
  static bool isSuccess(int code) => 200 <= code && code < 300;
}
