# flutter_netcore

[![pub package](https://img.shields.io/pub/v/flutter_netcore.svg)](https://pub.dev/packages/flutter_netcore)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible network client for Flutter applications built on top of [Dio](https://pub.dev/packages/dio). It provides a clean abstraction layer for HTTP communication with built-in support for retry policies, token refresh, connectivity detection, response parsing, and retry UI components.

---

## Features

- **Type-safe HTTP client** — Generic `send<TRes, TReq>()` method for strongly-typed requests and responses
- **Pluggable adapters** — `DioAdapter` included out of the box; swap in your own via `NetworkAdapter`
- **Response parsers** — `ModelParser`, `ListParser`, and `PrimitiveParser` for zero-boilerplate deserialization
- **Retry mechanism** — Configurable `RetryPolicy` (max attempts, delay, exponential backoff) with a `retryIf` predicate
- **Retry UI components** — Show retry prompts via `SnackbarRetryComponent`, `BannerRetryComponent`, `DialogRetryComponent`, or `BottomSheetRetryComponent`
- **Token refresh** — `refreshTokenHandler` and `refreshTokenFailHandler` hooks for transparent reauthentication
- **Connectivity detection** — Detects offline state before sending requests and notifies on network changes
- **Console logger** — Colorized request/response logging with `LogLevel` filtering
- **Cancel token** — Cancel in-flight requests with `NetcoreCancelToken`
- **Upload/download progress** — Track progress via `NetworkProgress`

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_netcore: ^0.0.1
```

Then run:

```sh
flutter pub get
```

---

## Quick Start

### 1. Create a `NetworkClient`

```dart
final client = NetworkClient(
  config: NetworkConfig(
    baseUrl: 'https://api.example.com',
    baseHeaders: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ),
);
```

### 2. Define a request

```dart
const request = NetworkRequest(
  '/users/1',
  method: HttpMethod.get,
);
```

### 3. Send the request and parse the response

```dart
final user = await client.send<User, void>(
  request: request,
  parser: ModelParser(User.fromJson),
);
```

### 4. Fetch a list

```dart
const request = NetworkRequest('/users', method: HttpMethod.get);

final users = await client.send<List<User>, void>(
  request: request,
  parser: ListParser.fromJson(User.fromJson),
);
```

---

## `NetworkConfig`

| Parameter | Type | Description |
|---|---|---|
| `baseUrl` | `String` | **Required.** Base URL for all requests |
| `baseHeaders` | `Map<String, dynamic>?` | Default headers applied to every request |
| `connectTimeout` | `Duration?` | Timeout for establishing a connection |
| `receiveTimeout` | `Duration?` | Timeout for receiving a response |
| `sendTimeout` | `Duration?` | Timeout for sending a request |
| `queryParameters` | `Map<String, dynamic>?` | Default query parameters |

---

## `NetworkRequest`

| Parameter | Type | Description |
|---|---|---|
| `path` | `String` | Endpoint path (appended to `baseUrl`) |
| `method` | `HttpMethod` | `get`, `post`, `put`, `patch`, `delete` |
| `headers` | `Map<String, dynamic>?` | Per-request headers |
| `queryParameters` | `Map<String, dynamic>?` | Per-request query parameters |
| `cancelToken` | `NetcoreCancelToken?` | Token to cancel this request |
| `responseType` | `NetcoreResponseType` | Response format, defaults to `json` |
| `extra` | `Map<String, Object?>?` | Arbitrary extra data passed through to the adapter |

---

## Parsers

### `ModelParser<T>`

Deserializes a JSON object into a model:

```dart
parser: ModelParser(User.fromJson)
```

### `ListParser<T>`

Deserializes a JSON array into a list of models:

```dart
parser: ListParser.fromJson(User.fromJson)
// or
parser: ListParser(ModelParser(User.fromJson))
```

### `PrimitiveParser<T>`

Returns primitive types (`String`, `int`, `double`, `bool`, `num`) directly:

```dart
parser: PrimitiveParser<int>()
```

---

## Retry

### `RetryPolicy`

Configure retry behavior globally or per-client:

```dart
const RetryPolicy(
  maxAttempts: 3,
  delay: Duration(milliseconds: 500),
  backoffFactor: 2.0, // delays: 500ms -> 1000ms -> 2000ms
)
```

### `NetworkRetry`

Attach a retry policy and an optional UI component:

```dart
NetworkClient(
  config: config,
  retry: NetworkRetry(
    policy: const RetryPolicy(maxAttempts: 3),
    retryIf: (e) => e is NoInternetException,
    component: SnackbarRetryComponent(context: context),
    hideDuration: const Duration(seconds: 3),
  ),
)
```

### Retry UI Components

| Component | Description |
|---|---|
| `SnackbarRetryComponent` | Shows a `SnackBar` with a retry action |
| `BannerRetryComponent` | Shows a `MaterialBanner` with a retry action |
| `DialogRetryComponent` | Shows an `AlertDialog` prompting the user to retry |
| `BottomSheetRetryComponent` | Shows a bottom sheet with a retry action |

---

## Token Refresh

Handle 401 responses automatically with `refreshTokenHandler`. Return the updated exception (with the new token in headers) to retry the original request, or return the original exception to propagate the error.

```dart
NetworkClient(
  config: config,
  refreshTokenHandler: (exception) async {
    final newToken = await refreshMyToken();
    exception.requestConfig?.headers?['Authorization'] = 'Bearer $newToken';
    return exception;
  },
  refreshTokenFailHandler: (exception) async {
    // e.g. navigate to login screen
    await logout();
  },
)
```

---

## Logging

Enable colorized request/response logs via `ConsoleLogger`:

```dart
NetworkClient(
  config: config,
  logger: ConsoleLogger(
    enabled: true,
    minimumLevel: LogLevel.debug,
  ),
)
```

Available log levels: `debug`, `info`, `warning`, `error`.

---

## Connectivity

Check the current connection status or subscribe to network changes:

```dart
final connectivity = NetcoreConnectivity();

// One-time check
final result = await connectivity.checkConnection();
if (result == NetcoreConnectivityResult.offline) {
  print('No internet connection');
}

// Subscribe to changes
connectivity.handleNetworkChange((result) {
  switch (result) {
    case NetcoreConnectivityResult.online:
      print('Back online');
    case NetcoreConnectivityResult.offline:
      print('Gone offline');
  }
});
```

`NetworkClient` automatically throws `NoInternetException` when the device is offline before sending any request.

---

## Cancel Token

Cancel a request at any time:

```dart
final cancelToken = NetcoreCancelToken();

client.send<User, void>(
  request: NetworkRequest(
    '/users/1',
    method: HttpMethod.get,
    cancelToken: cancelToken,
  ),
  parser: ModelParser(User.fromJson),
);

// Cancel the request
cancelToken.cancel();
```

---

## Upload / Download Progress

Track progress for large payloads:

```dart
await client.send<void, FormData>(
  request: NetworkRequest('/upload', method: HttpMethod.post),
  body: formData,
  progress: NetworkProgress(
    onSendProgress: (sent, total) => print('Sent: $sent / $total'),
    onReceiveProgress: (received, total) => print('Received: $received / $total'),
  ),
);
```

---

## Custom Adapter

Provide your own HTTP adapter by implementing `NetworkAdapter`:

```dart
class MyAdapter extends NetworkAdapter {
  @override
  void setConfig(NetworkConfig config, ILogger? logger) { ... }

  @override
  Future<NetworkResponse> request<TReq>(
    NetworkRequest request, {
    TReq? body,
    NetworkProgress? progress,
    NetworkRequestConfig? requestConfig,
  }) async { ... }
}

final client = NetworkClient(
  config: config,
  adapter: MyAdapter(),
);
```

---

## Exception Types

| Exception | Description |
|---|---|
| `NoInternetException` | Thrown when the device has no internet connectivity |
| `ParsingException` | Thrown when response deserialization fails |
| `AdapterException` | Thrown when the adapter is misconfigured |
| `NetcoreException` | Base class for all flutter_netcore exceptions |

---

## Full Example

A complete working example is available in the [`example/`](example/) directory, demonstrating authentication, CRUD operations, file upload/download, retry UI components, and token refresh.

---

## Additional Information

- **Repository:** [github.com/safauludogan/flutter_netcore](https://github.com/safauludogan/flutter_netcore)
- **Issues:** Please file bugs and feature requests on the [GitHub issue tracker](https://github.com/safauludogan/flutter_netcore/issues)

---

## License

[MIT](LICENSE)
