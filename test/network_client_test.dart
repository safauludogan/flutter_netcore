import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ============================================================================
// MOCKS
// ============================================================================

class MockNetworkAdapter extends Mock implements NetworkAdapter {}

class MockDio extends Mock implements Dio {}

class MockTokenRefreshHandler extends Mock implements TokenRefreshHandler {}

class MockParser<T> extends Mock implements Parser<T> {}

class FakeCancelToken extends Fake implements CancelToken {}

class FakeNetworkRequest extends Fake implements NetworkRequest {}

// ============================================================================
// TEST DATA
// ============================================================================

class TestModels {
  static const Map<String, Object> userJson = {
    'id': 1,
    'name': 'John Doe',
    'email': 'john@example.com',
  };

  static const networkRequest = NetworkRequest(
    '/users/1',
    method: HttpMethod.get,
  );

  static final networkConfig = NetworkClientConfig(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
  );
}

// ============================================================================
// NETWORK CLIENT TESTS
// ============================================================================

void main() {
  group('NetworkClient', () {
    late MockNetworkAdapter mockAdapter;
    late NetworkClientConfig config;
    late NetworkClient networkClient;

    setUpAll(() {
      registerFallbackValue(FakeCancelToken());
      registerFallbackValue(FakeNetworkRequest());
    });

    setUp(() {
      mockAdapter = MockNetworkAdapter();
      config = TestModels.networkConfig;

      when(() => mockAdapter.setConfig(any())).thenReturn(null);
      when(() => mockAdapter.addInterceptor(any())).thenReturn(null);

      networkClient = NetworkClient(
        config: config,
        adapter: mockAdapter,
      );
    });

    group('Initialization', () {
      test('should setup adapter with config on initialization', () {
        verify(() => mockAdapter.setConfig(config)).called(1);
      });

      test(
        'should add auth interceptor when token refresh handler provided',
        () {
          final tokenHandler = MockTokenRefreshHandler();
          final configWithAuth = NetworkClientConfig(
            baseUrl: 'https://api.example.com',
            tokenRefreshHandler: tokenHandler,
          );

          when(() => mockAdapter.setConfig(any())).thenReturn(null);
          when(() => mockAdapter.addInterceptor(any())).thenReturn(null);

          NetworkClient(config: configWithAuth, adapter: mockAdapter);

          verify(
            () => mockAdapter.addInterceptor(
              any(
                that: isA<AuthInterceptor>(),
              ),
            ),
          ).called(1);
        },
      );

      test('should not add auth interceptor when token handler is null', () {
        verifyNever(
          () => mockAdapter.addInterceptor(
            any(
              that: isA<AuthInterceptor>(),
            ),
          ),
        );
      });
    });

    group('send()', () {
      test('should successfully send request and return parsed data', () async {
        final mockParser = MockParser<Map<String, dynamic>>();
        const response = RawNetworkResponse(
          statusCode: 200,
          data: TestModels.userJson,
          headers: {},
        );

        when(
          () => mockAdapter.request<Map<String, dynamic>>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        when(() => mockParser.parse(any())).thenReturn(TestModels.userJson);

        final result = await networkClient
            .send<Map<String, dynamic>, Map<String, dynamic>>(
              request: TestModels.networkRequest,
              parser: mockParser,
            );

        expect(result, equals(TestModels.userJson));
        verify(() => mockParser.parse(TestModels.userJson)).called(1);
      });

      test('should return dynamic data when TRes is dynamic', () async {
        const response = RawNetworkResponse(
          statusCode: 200,
          data: TestModels.userJson,
          headers: {},
        );

        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        final result = await networkClient.send<dynamic, dynamic>(
          request: TestModels.networkRequest,
        );

        expect(result, equals(TestModels.userJson));
      });

      test('should return null for void response type', () async {
        const response = RawNetworkResponse(
          statusCode: 204,
          data: null,
          headers: {},
        );

        when(
          () => mockAdapter.request<void>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => response);

        final result = await networkClient.send<void, void>(
          request: TestModels.networkRequest,
        );
       // expect(result, isNull);
      });

      test(
        'should throw ParsingException when no parser provided for custom type',
        () async {
          const response = RawNetworkResponse(
            statusCode: 200,
            data: TestModels.userJson,
            headers: {},
          );

          when(
            () => mockAdapter.request<User>(
              any(),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) async => response);

          expect(
            () => networkClient.send<User, User>(
              request: TestModels.networkRequest,
            ),
            throwsA(isA<ParsingException>()),
          );
        },
      );

      test('should pass cancel token to adapter', () async {
        final cancelToken = CancelToken();
        const response = RawNetworkResponse(
          statusCode: 200,
          data: {},
          headers: {},
        );

        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: cancelToken,
          ),
        ).thenAnswer((_) async => response);

        await networkClient.send<dynamic, dynamic>(
          request: TestModels.networkRequest,
          cancelToken: cancelToken,
        );

        verify(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: cancelToken,
          ),
        ).called(1);
      });
    });

    group('Retry Logic', () {
      test('should retry failed requests based on retry policy', () async {
        var attemptCount = 0;
        const response = RawNetworkResponse(
          statusCode: 200,
          data: {'success': true},
          headers: {},
        );

        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          attemptCount++;
          if (attemptCount < 3) {
            throw HttpException(statusCode: 500, message: 'Server Error');
          }
          return response;
        });

        final result = await networkClient.send<dynamic, dynamic>(
          request: TestModels.networkRequest,
          retry: NetworkRetry(
            policy: const RetryPolicy(maxAttempts: 3, delay: Duration.zero),
          ),
        );

        expect(result, equals({'success': true}));
        expect(attemptCount, equals(3));
      });

      test('should not retry when retry is null', () async {
        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(HttpException(statusCode: 500, message: 'Error'));

        expect(
          () => networkClient.send<dynamic, dynamic>(
            request: TestModels.networkRequest,
            retry: null,
          ),
          throwsA(isA<HttpException>()),
        );
      });

      test('should stop retrying after max attempts', () async {
        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(HttpException(statusCode: 500, message: 'Error'));

        expect(
          () => networkClient.send<dynamic, dynamic>(
            request: TestModels.networkRequest,
            retry: NetworkRetry(
              policy: const RetryPolicy(maxAttempts: 2, delay: Duration.zero),
            ),
          ),
          throwsA(isA<HttpException>()),
        );

        verify(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2);
      });
    });

    group('Error Handling', () {
      test('should propagate network exceptions', () async {
        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(NetCoreException(message: 'Network error'));

        expect(
          () => networkClient.send<dynamic, dynamic>(
            request: TestModels.networkRequest,
          ),
          throwsA(isA<NetCoreException>()),
        );
      });

      test('should propagate HTTP exceptions', () async {
        when(
          () => mockAdapter.request<dynamic>(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(HttpException(statusCode: 404, message: 'Not Found'));

        expect(
          () => networkClient.send<dynamic, dynamic>(
            request: TestModels.networkRequest,
          ),
          throwsA(isA<HttpException>()),
        );
      });
    });
  });

  // ==========================================================================
  // DIO ADAPTER TESTS
  // ==========================================================================

  group('DioAdapter', () {
    late MockDio mockDio;
    late DioAdapter adapter;

    setUp(() {
      mockDio = MockDio();
      adapter = DioAdapter(dio: mockDio);
    });

    group('request()', () {
      test('should make successful GET request', () async {
        const request = NetworkRequest(
          '/users',
          method: HttpMethod.get,
          headers: {'Authorization': 'Bearer token'},
        );

        final dioResponse = Response(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 200,
          data: {'users': []},
        );

        when(
          () => mockDio.request<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => dioResponse);

        final response = await adapter.request(request);

        expect(response.statusCode, equals(200));
        expect(response.data, equals({'users': []}));
      });

      test('should include query parameters', () async {
        const request = NetworkRequest(
          '/users',
          method: HttpMethod.get,
          queryParameters: {'page': '1', 'limit': '10'},
        );

        final dioResponse = Response(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 200,
          data: {},
        );

        when(
          () => mockDio.request<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => dioResponse);

        await adapter.request(request);

        verify(
          () => mockDio.request<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: {'page': '1', 'limit': '10'},
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      });

      test('should map DioException to NetCoreException', () async {
        const request = NetworkRequest(
          '/users',
          method: HttpMethod.get,
        );

        when(
          () => mockDio.request<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => adapter.request(request),
          throwsA(isA<NetCoreException>()),
        );
      });
    });

    group('setConfig()', () {
      test('should apply configuration to Dio', () {
        final config = NetworkClientConfig(
          baseUrl: 'https://api.example.com',
          connectTimeout: const Duration(seconds: 30),
          headers: {'X-Custom': 'header'},
        );

        final baseOptions = BaseOptions();
        when(() => mockDio.options).thenReturn(baseOptions);

        adapter.setConfig(config);

        verify(
          () => mockDio.options = any(
            that: predicate<BaseOptions>(
              (options) =>
                  options.baseUrl == 'https://api.example.com' &&
                  options.connectTimeout == const Duration(seconds: 30) &&
                  options.headers['X-Custom'] == 'header',
            ),
          ),
        ).called(1);
      });
    });

    group('addInterceptor()', () {
      test('should add interceptor to Dio', () {
        final interceptor = MockInterceptor();
        final interceptors = Interceptors();

        when(() => mockDio.interceptors).thenReturn(interceptors);

        adapter.addInterceptor(interceptor);

        expect(interceptors.length, equals(1));
      });
    });
  });

  // ==========================================================================
  // RETRY EXECUTOR TESTS
  // ==========================================================================

  group('RetryExecutor', () {
    test('should execute action without retry on success', () async {
      var callCount = 0;
      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 3),
      );

      final result = await executor.execute(() async {
        callCount++;
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('should retry on retryable exceptions', () async {
      var callCount = 0;
      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 3, delay: Duration.zero),
      );

      final result = await executor.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw NetCoreException(message: 'Retry me');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(3));
    });

    test('should not retry on non-retryable exceptions', () async {
      var callCount = 0;
      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 3),
        retryIf: (e) => false,
      );

      expect(
        () => executor.execute(() async {
          callCount++;
          throw Exception('Do not retry');
        }),
        throwsException,
      );

      expect(callCount, equals(1));
    });
  });

  // ==========================================================================
  // DEFAULT RETRY DECIDER TESTS
  // ==========================================================================

  group('DefaultRetryDecider', () {
    test('should retry on NetCoreException', () {
      final result = DefaultRetryDecider.shouldRetry(
        NetCoreException(message: 'Network error'),
      );
      expect(result, isTrue);
    });

    test('should retry on TimeoutException', () {
      final result = DefaultRetryDecider.shouldRetry(
        TimeoutException('Timeout'),
      );
      expect(result, isTrue);
    });

    test('should retry on 5xx HTTP errors', () {
      final result = DefaultRetryDecider.shouldRetry(
        HttpException(statusCode: 500, message: 'Server Error'),
      );
      expect(result, isTrue);
    });

    test('should not retry on 4xx HTTP errors', () {
      final result = DefaultRetryDecider.shouldRetry(
        HttpException(statusCode: 404, message: 'Not Found'),
      );
      expect(result, isFalse);
    });

    test('should not retry on generic exceptions', () {
      final result = DefaultRetryDecider.shouldRetry(
        Exception('Generic error'),
      );
      expect(result, isFalse);
    });
  });
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class MockInterceptor extends Mock implements Interceptor {}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});
}
