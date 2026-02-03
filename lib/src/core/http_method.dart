/// Defines the HTTP methods used in network requests.
enum HttpMethod {
  /// Http GET method.
  get,

  /// Http POST method.
  post,

  /// Http PUT method.
  put,

  /// Http DELETE method.
  delete,

  /// Http PATCH method.
  patch,

  /// Http HEAD method.
  head,

  /// Http OPTIONS method.
  options
  ;

  /// Retrieves the [HttpMethod] enum value corresponding to the given method name.
  static HttpMethod getByName(String name) {
    return HttpMethod.values.firstWhere(
      (method) => method.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid HTTP method name: $name'),
    );
  }
}
