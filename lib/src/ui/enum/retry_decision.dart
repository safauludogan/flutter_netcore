/// Defines the possible decisions after a retry prompt.
enum RetryDecision {
  /// User chose to retry the operation.
  retry,
  /// User chose to cancel the operation.
  cancel,
}
