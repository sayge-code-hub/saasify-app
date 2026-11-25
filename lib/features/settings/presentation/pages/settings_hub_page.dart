import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/modules/module_access.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_hub_tile.dart';
import '../../../../injection_container.dart';

class SettingsHubPage extends StatefulWidget {
  const SettingsHubPage({super.key});

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final showModuleControls =
        sl.isRegistered<ModuleAccess>() && sl<ModuleAccess>().isPlatformAdmin;
    const standardTiles = [
      _SettingsTileData(
        title: 'Invite employee',
        icon: Icons.person_add_alt_1_outlined,
        path: AppRoutes.inviteEmployee,
      ),
      _SettingsTileData(
        title: 'Manage invites',
        icon: Icons.mark_email_unread_outlined,
        path: AppRoutes.manageInvites,
      ),
      _SettingsTileData(
        title: 'Manage clients',
        icon: Icons.apartment_outlined,
        path: AppRoutes.clients,
      ),
      _SettingsTileData(
        title: 'Company Details',
        icon: Icons.receipt_long_outlined,
        path: AppRoutes.companyDetails,
      ),
      _SettingsTileData(
        title: 'Billing',
        icon: Icons.credit_card_outlined,
        path: AppRoutes.billing,
      ),
      _SettingsTileData(
        title: 'Roles',
        icon: Icons.manage_accounts_outlined,
        path: AppRoutes.roles,
      ),
      _SettingsTileData(
        title: 'Activity ledger',
        icon: Icons.history_outlined,
        path: AppRoutes.ledger,
      ),
      _SettingsTileData(
        title: 'POS Categories',
        icon: Icons.category_outlined,
        path: AppRoutes.categories,
      ),
      _SettingsTileData(
        title: 'Theme',
        icon: Icons.palette_outlined,
        path: AppRoutes.theme,
      ),
    ];

    final query = _search.text.trim().toLowerCase();
    final tiles =
        [
              ...standardTiles,
              if (showModuleControls)
                const _SettingsTileData(
                  title: 'Product modules',
                  icon: Icons.tune_outlined,
                  path: AppRoutes.platformModules,
                ),
            ]
            .where(
              (tile) =>
                  query.isEmpty || tile.title.toLowerCase().contains(query),
            )
            .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        isDesktop ? 20 : 12,
        isDesktop ? 32 : 16,
        isDesktop ? 32 : 16,
      ),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isDesktop ? 28 : 24,
                  ),
                ),
              ),
              SizedBox(
                width: isDesktop ? 320 : 180,
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search settings',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tiles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  'No settings match your search.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: AppHubGrid.delegate(
                isDesktop: isDesktop,
                hasSubtitle: false,
                columns: 4,
              ),
              itemBuilder: (context, index) {
                final tile = tiles[index];
                return AppHubTile(
                  title: tile.title,
                  icon: tile.icon,
                  onTap: () => context.go(tile.path),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.title,
    required this.icon,
    required this.path,
  });

  final String title;
  final IconData icon;
  final String path;
}
