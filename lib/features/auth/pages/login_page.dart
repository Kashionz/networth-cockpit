import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../widgets/auth_form_shell.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String _email = '';
  String _password = '';
  bool _isSubmitting = false;

  bool get _canSubmit {
    return !_isSubmitting &&
        _email.trim().isNotEmpty &&
        _password.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: _email, password: _password);

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
      title: '登入',
      subtitle: '使用 Email 繼續，後續可補上進階驗證設定。',
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
      ],
      primaryLabel: _isSubmitting ? '登入中...' : '登入',
      onPrimaryPressed: _canSubmit ? _submit : null,
      onGooglePressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google OAuth 將於後續版本串接')));
      },
    );
  }
}
