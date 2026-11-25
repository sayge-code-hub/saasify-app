import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/sign_out_usecase.dart';

/// Shown only after an owner deliberately enables subscription enforcement.
class SubscriptionRequiredPage extends StatefulWidget {
  const SubscriptionRequiredPage({super.key});

  @override
  State<SubscriptionRequiredPage> createState() =>
      _SubscriptionRequiredPageState();
}

class _SubscriptionRequiredPageState extends State<SubscriptionRequiredPage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await sl<SignOutUseCase>()();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 42,
                  color: AppColors.text,
                ),
                const SizedBox(height: 16),
                Text(
                  'Subscription required',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your company does not have an active Saasify subscription. '
                  'Please contact your company owner to restore access.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 24),
                AppOutlinedButton(
                  label: 'Sign out',
                  expand: true,
                  enabled: !_signingOut,
                  onPressed: _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
