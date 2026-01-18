/// Defines a policy for retrying operations with configurable parameters.
class RetryPolicy {
  /// Creates a [RetryPolicy] with the given parameters.
  const RetryPolicy({
    this.maxAttempts = 3,
    this.delay = const Duration(milliseconds: 500),
    this.backoffFactor = 2.0,
  });

  /// The maximum number of retry attempts.
  final int maxAttempts;

  /// The initial delay before the first retry attempt.
  final Duration delay;

  /// The factor by which the delay increases after each attempt.
  final double backoffFactor;
}
