import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

/// Custom banner that appears at the top/bottom of screen
class BannerRetryComponent extends NetworkRetryComponent {
  BannerRetryComponent({
    required this.scaffoldMessengerKey,
    required super.context,
    super.messageBuilder,
    super.maxManualRetries,
    this.retry = 'Retry',
    this.dismiss = 'Dismiss',
    this.showAtTop = true,
    this.backgroundColor,
  });

  /// The ScaffoldMessengerKey to show the banner in.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  /// Whether to show the banner at the top or bottom of the screen.
  final bool showAtTop;

  /// Background color of the banner.
  final Color? backgroundColor;

  /// Label for the retry action.
  final String retry;

  /// Label for the dismiss action.
  final String dismiss;

  @override
  Future<RetryDecision> show({
    required NetCoreException error,
  }) async {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return RetryDecision.cancel;

    final message =
        messageBuilder?.call(error) ?? 'Failed to connect to server';

    var retryIf = false;

    final controller = messenger.showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
        backgroundColor: backgroundColor ?? const Color(0xFFB3261E),
        leading: const Icon(
          Icons.wifi_off,
          size: 20,
          color: Color(0xFFFFDAD6),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            height: 1.25,
            color: Color(0xFFFFEDEA),
          ),
        ),
        actions: [
          /// Dismiss button
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFFFDAD6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              retryIf = false;
              hide();
            },
            child: Text(dismiss),
          ),

          /// Retry button
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFFFFBFF),
              backgroundColor: const Color(
                0x40FFFFFF,
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              retryIf = true;
              hide();
            },
            child: Text(retry),
          ),
        ],
      ),
    );

    return controller.closed.then((reason) {
      return retryIf ? RetryDecision.retry : RetryDecision.cancel;
    });
  }

  @override
  void hide() {
    scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
  }
}
