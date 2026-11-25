import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/app_access.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/google_auth_intent.dart';
import '../../../../core/billing/billing_access.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/modules/module_access.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_page_scaffold.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/auth_remote_datasource.dart';

/// Captures workspace details only after a new user has authenticated with Google.
class GoogleOnboardingPage extends StatefulWidget {
  const GoogleOnboardingPage({super.key});

  @override
  State<GoogleOnboardingPage> createState() => _GoogleOnboardingPageState();
}

class _GoogleOnboardingPageState extends State<GoogleOnboardingPage> {
  late final TextEditingController _company = TextEditingController();
  late final TextEditingController _name = TextEditingController(
    text: _googleName,
  );
  bool _saving = false;
  String? _error;

  String get _googleName {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    return (metadata?['full_name'] ?? metadata?['name'] ?? '')
        .toString()
        .trim();
  }

  @override
  void initState() {
    super.initState();
    if (Supabase.instance.client.auth.currentSession == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.signup),
      );
    }
  }

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_saving) return;
    final company = _company.text.trim();
    final name = _name.text.trim();
    if (company.isEmpty || name.isEmpty) {
      setState(() => _error = 'Enter your company name and your name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': name, 'name': name}),
      );
      await client.rpc(
        'saasify_complete_signup',
        params: {'p_company_name': company, 'p_display_name': company},
      );
      await GoogleAuthFlow.clear();
      final profile = await sl<AuthRemoteDataSource>().restoreSession();
      if (profile == null) {
        throw StateError('Your workspace could not be created.');
      }
      await sl<AuthSession>().setUser(profile, needsPasswordSetup: false);
      await sl<BillingAccess>().refresh();
      await sl<ModuleAccess>().refresh();
      if (mounted) context.go(AppAccess.homeRoute(profile));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);
    return AuthPageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/images/saasify_logo.png',
            height: compact ? 40 : 48,
            fit: BoxFit.contain,
            semanticLabel: 'Saasify',
          ),
          SizedBox(height: compact ? 18 : 24),
          Text(
            'Set up your workspace',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your Google account is connected. Add the last few details to continue.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _company,
            label: 'Company name',
            hintText: 'Acme Cafe',
            textInputAction: TextInputAction.next,
            enabled: !_saving,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _name,
            label: 'Your name',
            textInputAction: TextInputAction.done,
            enabled: !_saving,
            onSubmitted: (_) => _complete(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: _saving ? 'Creating workspace…' : 'Continue',
            isLoading: _saving,
            onPressed: _saving ? null : _complete,
          ),
        ],
      ),
    );
  }
}
