import 'dart:core' as core;

import '_http_status_codes.dart';

/// Base [Exception] class for CosmosDB errors.
class Exception implements core.Exception {
  Exception(core.String method, this.url, this.statusCode, this.message)
      : method = method.toUpperCase();

  final core.String method;
  final core.String url;
  final core.int statusCode;
  final core.String message;

  @core.override
  core.String toString() => '$method $url: $runtimeType ($statusCode)';
}

class UnauthorizedException extends Exception {
  UnauthorizedException(core.String method, core.String url,
      {core.int statusCode = HttpStatusCode.unauthorized, core.String? message})
      : super(method, url, statusCode, message ?? '');
}

class ForbiddenException extends Exception {
  ForbiddenException(core.String method, core.String url,
      {core.int statusCode = HttpStatusCode.forbidden, core.String? message})
      : super(method, url, statusCode, message ?? '');
}

class ConflictException extends Exception {
  ConflictException(core.String method, core.String url,
      {core.int statusCode = HttpStatusCode.conflict, core.String? message})
      : super(method, url, statusCode, message ?? '');
}

class NotFoundException extends Exception {
  NotFoundException(core.String method, core.String url,
      {core.int statusCode = HttpStatusCode.notFound, core.String? message})
      : super(method, url, statusCode, message ?? '');
}
