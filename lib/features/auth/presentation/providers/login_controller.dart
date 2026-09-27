import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Drives the login screen's submit button: `AsyncLoading` while the
/// request is in flight, `AsyncError(Failure)` on failure, `AsyncData(null)`
/// once it succeeds (the actual navigation is driven separately by
/// [authStateChangesProvider]).
class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final useCase = ref.read(signInUseCaseProvider);
    final result = await useCase(email: email, password: password);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
