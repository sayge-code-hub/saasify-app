/// Display and storage-key protections for employee PII.
abstract final class SensitiveData {
  static String mask(String value, {int visibleTail = 4}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= visibleTail) return '•' * trimmed.length;
    return '${'•' * (trimmed.length - visibleTail)}${trimmed.substring(trimmed.length - visibleTail)}';
  }

  /// Storage object keys are not filesystem paths. Still reject traversal-like
  /// keys and require the exact employee document namespace before copying one
  /// into a public avatar bucket.
  static bool isEmployeeDocumentPath(String path, String employeeId) {
    final normalized = path.trim();
    final id = employeeId.trim();
    if (normalized.isEmpty || id.isEmpty) return false;
    if (normalized.contains('..') ||
        normalized.contains('\\') ||
        normalized.contains('//')) {
      return false;
    }
    return normalized.startsWith('documents/employee/$id/');
  }

  static bool isImageFileName(String fileName) {
    final lower = fileName.trim().toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
