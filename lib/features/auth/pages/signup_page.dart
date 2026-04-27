import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../widgets/auth_form_shell.dart';
import '../widgets/investment_disclaimer_checkbox.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  String _email = '';
  String _password = '';
  bool _acknowledged = false;
  bool _isSubmitting = false;

  bool get _canSubmit {
    return !_isSubmitting &&
        _email.trim().isNotEmpty &&
        _password.trim().isNotEmpty &&
        _acknowledged;
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(email: _email, password: _password);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormShell(
      title: '註冊',
      subtitle: '建立帳號後即可開始整理資產與月度回顧。',
      fields: [
        AppTextField(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (value) => setState(() => _email = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: '密碼',
          obscureText: true,
          onChanged: (value) => setState(() => _password = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        InvestmentDisclaimerCheckbox(
          value: _acknowledged,
          onChanged: (value) => setState(() => _acknowledged = value),
        ),
      ],
      primaryLabel: _isSubmitting ? '建立中...' : '建立帳號',
      onPrimaryPressed: _canSubmit ? _submit : null,
      onGooglePressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google OAuth 將於後續版本串接')));
      },
    );
  }
}
