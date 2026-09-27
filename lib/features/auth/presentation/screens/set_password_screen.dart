import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/async_value_x.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_providers.dart';
import '../providers/set_password_controller.dart';
import '../widgets/gradient_pill_button.dart';

/// Mandatory one-time gate for accounts created purely through Google:
/// the router sends every signed-in user here until they set a password,
/// so the account can always be reached both ways (see
/// [AppUser.hasPasswordIdentity]).
///
/// Navigates to Home explicitly on success rather than waiting for the
/// router to notice the auth stream change by itself — by the time the
/// controller resolves, `AuthRepository.currentUser` is already updated
/// (the datasource awaits that before returning), so there's no reason to
/// depend on the stream's timing for something this simple.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _hasSubmitted = true;
    ref
        .read(setPasswordControllerProvider.notifier)
        .submit(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setPasswordControllerProvider);

    ref.listen(setPasswordControllerProvider, (previous, next) {
      if (!_hasSubmitted) return;

      final message = next.failureMessageOrNull;
      if (message != null) {
        AppToast.show(context, message: message);
        return;
      }
      if (next.hasValue && !next.isLoading) {
        context.go(AppRoutes.home);
      }
    });

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
                  const Icon(
                    Icons.password_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Postavite lozinku',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prijavili ste se preko Google naloga. Postavite lozinku '
                    'da biste ubuduće mogli da se prijavite i direktno, '
                    'e-mailom i lozinkom.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nova lozinka',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Minimum 6 karaktera';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Ponovite lozinku',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Lozinke se ne poklapaju';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 20),
                          GradientPillButton(
                            label: 'Postavi lozinku',
                            isLoading: state.isLoading,
                            onPressed: state.isLoading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text(
                      'Odjavi se',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
