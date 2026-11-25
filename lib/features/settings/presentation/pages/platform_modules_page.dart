import 'package:flutter/material.dart';

import '../../../../core/modules/module_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';

class PlatformModulesPage extends StatefulWidget {
  const PlatformModulesPage({super.key});

  @override
  State<PlatformModulesPage> createState() => _PlatformModulesPageState();
}

class _PlatformModulesPageState extends State<PlatformModulesPage> {
  ModuleAccess get _modules => sl<ModuleAccess>();
  SaasifyModule? _saving;

  @override
  void initState() {
    super.initState();
    _modules.refresh();
  }

  Future<void> _toggle(SaasifyModule module, bool enabled) async {
    setState(() => _saving = module);
    try {
      await _modules.setEnabled(module, enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the module setting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _modules,
      builder: (context, _) {
        if (!_modules.isPlatformAdmin) {
          return const Center(
            child: Text('This page is restricted to the platform owner.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Product modules',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'These are master switches for the entire Saasify product. They are independent of billing and subscriptions.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            for (final module in SaasifyModule.values)
              Card(
                child: SwitchListTile.adaptive(
                  title: Text(module.label),
                  subtitle: Text(
                    _modules.isEnabled(module)
                        ? 'Visible to eligible users'
                        : 'Hidden for all users',
                  ),
                  value: _modules.isEnabled(module),
                  onChanged: _saving == null
                      ? (enabled) => _toggle(module, enabled)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}
