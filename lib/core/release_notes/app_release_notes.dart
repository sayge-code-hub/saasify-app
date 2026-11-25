/// Curated release notes shown from the version easter egg.
///
/// Versioning uses three-part semver (`MAJOR.MINOR.PATCH`). The production
/// deployment workflow calculates and stamps the next patch before building.
class AppReleaseNote {
  const AppReleaseNote({
    required this.version,
    required this.releasedAt,
    required this.title,
    required this.highlights,
  });

  final String version;
  final DateTime releasedAt;
  final String title;
  final List<String> highlights;

  String get label => 'v$version';
}

/// History starts clean with the 1.0.0 reset. GitHub releases are canonical.
abstract final class AppReleaseNotes {
  static const currentVersionHint = '1.0.0';
  static const List<AppReleaseNote> all = [];

  static AppReleaseNote? find(String version) {
    final normalized = version.trim().replaceFirst(RegExp(r'^v'), '');
    for (final note in all) {
      if (note.version == normalized) return note;
    }
    return null;
  }
}
