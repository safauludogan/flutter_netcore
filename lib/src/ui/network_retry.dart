// ignore_for_file: public_member_api_docs

import 'package:flutter_netcore/src/retry/retry_policy.dart';
import 'package:flutter_netcore/src/ui/components/index.dart';

/// Class representing a network retry mechanism.
class NetworkRetry {
  NetworkRetry({
    this.policy,
    this.retryIf,
    this.component,
    this.hideDuration,
  });

  /// UI component to display retry options.
  final NetworkRetryComponent? component;

  /// The retry policy defining the conditions and limits for retries.
  final RetryPolicy? policy;

  /// Condition to determine if retry should be attempted
  final bool Function(Exception)? retryIf;

  /// Optional duration after which the component hides itself.
  /// If null, the component will not auto-hide.
  Duration? hideDuration;
}
