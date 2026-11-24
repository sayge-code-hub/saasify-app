import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/app_access.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/password_setup.dart';
import '../../../../core/billing/billing_access.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_version_label.dart';
import '../../../../core/widgets/auth_page_scaffold.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../bloc/login_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginBloc>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _handlingGoogleSignIn = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedIn) {
        _completeGoogleSignIn();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _completeGoogleSignIn(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _completeGoogleSignIn() async {
    if (_handlingGoogleSignIn || !mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    final signedInWithGoogle =
        user?.appMetadata['provider']?.toString() == 'google' ||
        (user?.identities?.any((identity) => identity.provider == 'google') ??
            false);
    if (!signedInWithGoogle) return;

    _handlingGoogleSignIn = true;
    try {
      final profile = await sl<AuthRemoteDataSource>().restoreSession();
      if (profile == null) {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This Google account is not authorized for Saasify. Ask your administrator for an invite.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await sl<AuthSession>().setUser(profile, needsPasswordSetup: false);
      await sl<BillingAccess>().refresh();
      if (mounted) context.go(AppAccess.homeRoute(profile));
    } finally {
      _handlingGoogleSignIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == LoginStatus.success && state.user != null) {
          final needsSetup = PasswordSetup.currentUserRequiresSetup();
          await sl<AuthSession>().setUser(
            state.user!,
            needsPasswordSetup: needsSetup,
          );
          await sl<BillingAccess>().refresh();
          if (!context.mounted) return;
          context.go(
            needsSetup
                ? AppRoutes.setPassword
                : AppAccess.homeRoute(state.user!),
          );
        }
      },
      child: AuthPageScaffold(
        footer: const AppVersionLabel(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginHeader(),
            SizedBox(height: Breakpoints.isCompact(context) ? 24 : 28),
            const LoginForm(),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Image.asset(
            'assets/images/saasify_logo.png',
            height: compact ? 40 : 48,
            fit: BoxFit.contain,
            semanticLabel: 'Saasify',
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        Text(
          'Welcome back. Sign in to continue.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.35),
        ),
      ],
    );
  }
}
