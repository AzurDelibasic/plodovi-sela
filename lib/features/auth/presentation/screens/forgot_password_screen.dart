import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/async_value_x.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/forgot_password_controller.dart';
import '../widgets/gradient_pill_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _hasSubmitted = true;
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      if (!_hasSubmitted) return;

      final message = next.failureMessageOrNull;
      if (message != null) {
        AppToast.show(context, message: message);
        return;
      }
      if (next.hasValue && !next.isLoading) {
        setState(() => _emailSent = true);
      }
    });

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_reset_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Zaboravljena lozinka',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unesite e-mail povezan sa vašim nalogom — poslaćemo vam link za resetovanje lozinke.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
                          child: _emailSent
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.mark_email_read_outlined,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Provjerite svoj e-mail (${_emailController.text}) za link za resetovanje lozinke.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        decoration: const InputDecoration(
                                          labelText: 'E-mail',
                                          prefixIcon: Icon(Icons.mail_outline),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              !value.contains('@')) {
                                            return 'Unesite validan e-mail';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (_) => _submit(),
                                      ),
                                      const SizedBox(height: 20),
                                      GradientPillButton(
                                        label: 'Pošalji link',
                                        isLoading: state.isLoading,
                                        onPressed: state.isLoading
                                            ? null
                                            : _submit,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
