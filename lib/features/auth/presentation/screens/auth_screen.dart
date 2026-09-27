import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/async_value_x.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/google_sign_in_controller.dart';
import '../providers/login_controller.dart';
import '../providers/register_controller.dart';
import '../widgets/auth_mode_switch.dart';
import '../widgets/google_logo.dart';
import '../widgets/gradient_pill_button.dart';

/// Combined login/register screen: a gradient hero with a pill segmented
/// control that swaps between the two forms inside a rounded white card.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.login;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _obscureRegisterPassword = true;
  bool _hasSubmittedRegister = false;
  bool _registrationEmailSent = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );
  }

  void _submitRegister() {
    if (!_registerFormKey.currentState!.validate()) return;
    _hasSubmittedRegister = true;
    ref
        .read(registerControllerProvider.notifier)
        .submit(
          email: _registerEmailController.text,
          password: _registerPasswordController.text,
          fullName: _registerNameController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final registerState = ref.watch(registerControllerProvider);
    final googleState = ref.watch(googleSignInControllerProvider);

    ref.listen(loginControllerProvider, (_, next) => _showErrorIfAny(next));
    ref.listen(registerControllerProvider, (_, next) {
      if (!_hasSubmittedRegister) return;
      _showErrorIfAny(next);
      if (next.hasValue && !next.isLoading && next.value == true) {
        setState(() => _registrationEmailSent = true);
      }
    });
    ref.listen(
      googleSignInControllerProvider,
      (_, next) => _showErrorIfAny(next),
    );

    final isBusy =
        loginState.isLoading ||
        registerState.isLoading ||
        googleState.isLoading;

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco_rounded, size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'Plodovi sela',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Domaće namirnice, direktno sa sela do tvog stola',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthModeSwitch(
                    mode: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _mode == AuthMode.login
                          ? _buildLoginForm(
                              isBusy: isBusy,
                              isLoading: loginState.isLoading,
                            )
                          : _buildRegisterForm(
                              isBusy: isBusy,
                              isLoading: registerState.isLoading,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGoogleButton(
                    isBusy: isBusy,
                    isLoading: googleState.isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorIfAny<T>(AsyncValue<T> value) {
    final message = value.failureMessageOrNull;
    if (message == null) return;
    AppToast.show(context, message: message);
  }

  Widget _buildLoginForm({required bool isBusy, required bool isLoading}) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Unesite e-mail'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureLoginPassword = !_obscureLoginPassword,
                ),
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Unesite lozinku' : null,
            onFieldSubmitted: (_) => _submitLogin(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isBusy
                  ? null
                  : () => context.push(AppRoutes.forgotPassword),
              child: const Text('Zaboravili ste lozinku?'),
            ),
          ),
          const SizedBox(height: 8),
          GradientPillButton(
            label: 'Prijavi se',
            isLoading: isLoading,
            onPressed: isBusy ? null : _submitLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm({required bool isBusy, required bool isLoading}) {
    if (_registrationEmailSent) {
      return Column(
        key: const ValueKey('register-confirm-email'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nalog je napravljen!',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Poslali smo vam link za potvrdu na ${_registerEmailController.text}. '
            'Potvrdite e-mail da biste se mogli prijaviti.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _registrationEmailSent = false;
              _hasSubmittedRegister = false;
              _mode = AuthMode.login;
            }),
            child: const Text('Nazad na prijavu'),
          ),
        ],
      );
    }

    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Ime i prezime',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Unesite ime' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Unesite e-mail'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureRegisterPassword = !_obscureRegisterPassword,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Minimum 6 karaktera';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitRegister(),
          ),
          const SizedBox(height: 20),
          GradientPillButton(
            label: 'Napravi nalog',
            isLoading: isLoading,
            onPressed: isBusy ? null : _submitRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton({required bool isBusy, required bool isLoading}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ili',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isBusy
                ? null
                : () => ref
                      .read(googleSignInControllerProvider.notifier)
                      .submit(),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      GoogleLogo(),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Nastavi sa Google nalogom',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
