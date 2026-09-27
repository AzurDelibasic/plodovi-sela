import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failures.dart';

/// Convenience for pulling a human-readable message out of an
/// `AsyncNotifier` error state, which in this app is always a [Failure]
/// (see the auth controllers).
extension FailureMessage<T> on AsyncValue<T> {
  String? get failureMessageOrNull {
    return whenOrNull(error: (error, _) => (error as Failure).message);
  }
}
