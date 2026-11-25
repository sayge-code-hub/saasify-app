import 'dart:developer' as developer;

/// Records a recoverable operational failure without serialising potentially
/// sensitive request data (such as email addresses, file paths, or payloads).
///
/// Callers may continue only when the failed work is genuinely best-effort,
/// such as deleting an obsolete file after its replacement has succeeded.
void reportRecoverableFailure(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  developer.log(
    '$operation failed (${error.runtimeType})',
    name: 'saasify.operational',
    stackTrace: stackTrace,
  );
}
