import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String email) async {
    state = const AsyncLoading();
    final useCase = ref.read(sendPasswordResetEmailUseCaseProvider);
    final result = await useCase(email);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );
