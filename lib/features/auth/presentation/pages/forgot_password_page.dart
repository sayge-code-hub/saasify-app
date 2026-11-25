import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_page_scaffold.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/reset_password_usecase.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final email = _email.text.trim().toLowerCase();
    final error = Validators.email(email);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await sl<ResetPasswordUseCase>()(email);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) => setState(() => _sent = true),
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);
    final textTheme = Theme.of(context).textTheme;
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
          SizedBox(height: compact ? 22 : 28),
          Text(
            _sent ? 'Check your email' : 'Reset your password',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            _sent
                ? 'If an account exists for ${_email.text.trim()}, we sent a reset link.'
                : 'Enter your email and we will send you a secure reset link.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          if (!_sent) ...[
            AppTextField(
              controller: _email,
              label: 'Email',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !_sending,
              errorText: _error,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: _sending ? 'Sending…' : 'Send reset link',
              isLoading: _sending,
              onPressed: _sending ? null : _submit,
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(_sent ? 'Back to sign in' : 'Back to sign in'),
          ),
        ],
      ),
    );
  }
}
