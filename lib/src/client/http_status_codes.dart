abstract class HttpStatusCode {
  static const ok = 200;
  static const created = 201;
  static const noContent = 204;
  static const notModified = 304;
  static const notFound = 404;
  static const unauthorized = 401;
  static const forbidden = 403;
  static const conflict = 409;
  static const preconditionFailure = 412;
  static const failedDependency = 424;
  static const tooManyRequests = 429;
  static const serverError = 500;

  static bool success(int statusCode) => 200 <= statusCode && statusCode < 300;
}
