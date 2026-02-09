import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Callback signature used to notify connectivity state changes.
typedef NetworkCallback = void Function(NetcoreConnectivityResult result);

/// Contract that defines network connectivity operations.
///
/// Implementations are expected to:
/// - Provide a way to listen for connectivity changes
/// - Allow one-time connectivity checks
/// - Properly manage lifecycle and cleanup resources
abstract class INetcoreConnectivity {
  /// Starts listening to network connectivity changes.
  ///
  /// [onChange] will be triggered every time the connectivity state changes,
  /// emitting a mapped [NetcoreConnectivityResult].
  void handleNetworkChange(NetworkCallback onChange);

  /// Performs a one-time connectivity check.
  ///
  /// Returns the current [NetcoreConnectivityResult] without
  /// subscribing to continuous updates.
  Future<NetcoreConnectivityResult> checkConnection();

  /// Cancels active subscriptions and releases resources.
  ///
  /// Should be called when connectivity tracking is no longer needed
  /// (e.g. on app dispose or shutdown).
  Future<void> dispose();
}

/// Singleton implementation of [INetcoreConnectivity].
///
/// This class wraps `connectivity_plus` and exposes a simplified,
/// app-level connectivity state (`online` / `offline`).
///
/// Why singleton?
/// - Connectivity is an app-wide concern
/// - Prevents multiple stream subscriptions
/// - Centralized lifecycle management
class NetcoreConnectivity implements INetcoreConnectivity {
  /// Internal singleton instance.
  static final NetcoreConnectivity _instance = NetcoreConnectivity._internal();

  /// Factory constructor returning the singleton instance.
  factory NetcoreConnectivity() => _instance;

  /// Private constructor.
  NetcoreConnectivity._internal() : _connectivity = Connectivity();

  /// Underlying connectivity_plus client.
  final Connectivity _connectivity;

  /// Active connectivity change subscription.
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<void> handleNetworkChange(NetworkCallback onChange) async {
    // Ensure only one active listener exists.
    await _subscription?.cancel();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      onChange(
        NetcoreConnectivityResult.fromConnectivityList(results),
      );
    });
  }

  @override
  Future<NetcoreConnectivityResult> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return NetcoreConnectivityResult.fromConnectivityList(results);
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

/// High-level connectivity state used by Netcore.
///
/// This enum intentionally abstracts away platform-specific
/// connectivity types and exposes only meaningful states
/// for application logic.
enum NetcoreConnectivityResult {
  /// Device has an active network connection.
  online,

  /// Device has no network connection.
  offline
  ;

  /// Maps a list of [ConnectivityResult] values to a single
  /// [NetcoreConnectivityResult].
  ///
  /// - If the list is empty or contains [ConnectivityResult.none],
  ///   the device is considered [offline].
  /// - If any known transport is available, the device is [online].
  static NetcoreConnectivityResult fromConnectivityList(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetcoreConnectivityResult.offline;
    }

    if (results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other ||
          r == ConnectivityResult.bluetooth,
    )) {
      return NetcoreConnectivityResult.online;
    }

    return NetcoreConnectivityResult.offline;
  }

  /// Convenience getter to improve readability in consumers.
  ///
  /// Example:
  /// ```dart
  /// if (result.isOnline) { ... }
  /// ```
  bool get isOnline => this == NetcoreConnectivityResult.online;
}


///Example DI register:
/*
final getIt = GetIt.instance;

void setupDI() {
  getIt.registerSingleton<INetcoreConnectivity>(
    NetcoreConnectivity(),
  );
}

final connectivity = getIt<INetcoreConnectivity>();

final status = await connectivity.checkConnection();


Listen;
final connectivity = NetcoreConnectivity();

connectivity.handleNetworkChange((result) {
  switch (result) {
    case NetcoreConnectivityResult.online:
      debugPrint('Network connected');
      break;
    case NetcoreConnectivityResult.offline:
      debugPrint('Network disconnected');
      break;
  }
});


*/