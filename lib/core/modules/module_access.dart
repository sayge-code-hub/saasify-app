import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observability/operational_log.dart';

enum SaasifyModule { hrms, dms, finances, pos }

extension SaasifyModuleX on SaasifyModule {
  String get key => name;

  String get label => switch (this) {
    SaasifyModule.hrms => 'HRMS',
    SaasifyModule.dms => 'DMS',
    SaasifyModule.finances => 'Finances',
    SaasifyModule.pos => 'POS',
  };
}

/// Global product-module switches, independent of subscription billing.
class ModuleAccess extends ChangeNotifier {
  ModuleAccess({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  Map<String, bool> _enabled = {
    for (final module in SaasifyModule.values) module.key: true,
  };
  bool _loaded = false;
  bool _isPlatformAdmin = false;

  bool get loaded => _loaded;
  bool get isPlatformAdmin => _isPlatformAdmin;
  bool isEnabled(SaasifyModule module) => _enabled[module.key] ?? false;

  Future<void> refresh() async {
    try {
      final raw = await _client.rpc('platform_modules_state');
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final modules = map['modules'] is Map
          ? Map<String, dynamic>.from(map['modules'] as Map)
          : <String, dynamic>{};
      _enabled = {
        for (final module in SaasifyModule.values)
          module.key: modules[module.key] == true,
      };
      _isPlatformAdmin = map['is_platform_admin'] == true;
    } catch (error, stackTrace) {
      reportRecoverableFailure('Load platform module controls', error, stackTrace);
      // Retain the last known state. Older deployments remain usable until the
      // module-control migration is installed.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(SaasifyModule module, bool enabled) async {
    if (!_isPlatformAdmin) {
      throw StateError('You do not have permission to manage product modules.');
    }
    await _client.rpc(
      'platform_set_module_enabled',
      params: {'p_module': module.key, 'p_enabled': enabled},
    );
    _enabled = {..._enabled, module.key: enabled};
    notifyListeners();
  }

  void reset() {
    _enabled = {for (final module in SaasifyModule.values) module.key: true};
    _loaded = false;
    _isPlatformAdmin = false;
    notifyListeners();
  }
}
