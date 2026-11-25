import 'package:flutter/foundation.dart';

/// Signals shell surfaces to reload the active company's visual identity.
///
/// The company details screen owns the upload; the sidebar listens here so a
/// newly saved logo is visible immediately without a full page refresh.
abstract final class CompanyBranding {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void refresh() => revision.value++;
}
