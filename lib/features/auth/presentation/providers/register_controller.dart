import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// State is `true` when the sign-up succeeded but Supabase requires the
/// user to confirm their e-mail before a session exists (project setting
/// "Confirm email"), `false` when they're already signed in.
class RegisterController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    final useCase = ref.read(signUpUseCaseProvider);
    final result = await useCase(
      email: email,
      password: password,
      fullName: fullName,
    );

    state = result.fold((failure) => AsyncError(failure, StackTrace.current), (
      _,
    ) {
      final requiresEmailConfirmation =
          ref.read(authRepositoryProvider).currentUser == null;
      return AsyncData(requiresEmailConfirmation);
    });
  }
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, bool>(RegisterController.new);
