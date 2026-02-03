import 'package:flutter_netcore/flutter_netcore.dart';

/// Mixin to provide common adapter functionalities.
mixin AdapterMixin {
  /// Emit progress bar
  void emitProgress(
    ProgressCallback? callback,
    int count,
    int total,
  ) {
    if (callback == null) return;
    final progress = total > 0 ? count / total : 0.0;

    callback(
      count,
      total,
      progress.clamp(0.0, 1.0),
    );
  }
}
