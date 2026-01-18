import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/ui/components/network_retry_component.dart';

/// Custom banner that appears at the top/bottom of screen
class BannerRetryComponent extends NetworkRetryComponent {
  BannerRetryComponent({
    required this.scaffoldMessengerKey,
    this.showAtTop = true,
    this.backgroundColor,
    this.duration = const Duration(seconds: 10),
  });

  /// The ScaffoldMessengerKey to show the banner in.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  /// Whether to show the banner at the top or bottom of the screen.
  final bool showAtTop;

  /// Background color of the banner.
  final Color? backgroundColor;

  /// Duration for which the banner is displayed.
  final Duration duration;

  @override
  void show({
    required Exception error,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    scaffoldMessengerKey.currentState?.showMaterialBanner(
      MaterialBanner(
        content: Text('Network error: $error'),
        backgroundColor: backgroundColor ?? Colors.red.shade100,
        leading: const Icon(Icons.wifi_off, color: Colors.red),
        actions: [
          TextButton(
            onPressed: () {
              hide();
              onCancel();
            },
            child: const Text('DISMISS'),
          ),
          ElevatedButton(
            onPressed: () {
              hide();
              onRetry();
            },
            child: const Text('RETRY'),
          ),
        ],
      ),
    );

    // Auto-hide after duration
    Future.delayed(duration, hide);
  }

  @override
  void hide() {
    scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
  }
}
