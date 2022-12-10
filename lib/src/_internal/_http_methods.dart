class HttpMethod {
  const HttpMethod._(this.name, this.isReadOnly);

  final String name;
  final bool isReadOnly;

  static const get = HttpMethod._('GET', true);
  static const post = HttpMethod._('POST', false);
  static const put = HttpMethod._('PUT', false);
  static const patch = HttpMethod._('PATCH', false);
  static const delete = HttpMethod._('DELETE', false);
}
