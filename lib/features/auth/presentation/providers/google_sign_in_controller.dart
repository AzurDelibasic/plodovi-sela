import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Shared by both the login and register tabs — "Continue with Google" is
/// the same action regardless of which tab is showing.
class GoogleSignInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit() async {
    state = const AsyncLoading();
    final useCase = ref.read(signInWithGoogleUseCaseProvider);
    final result = await useCase();

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

final googleSignInControllerProvider =
    AsyncNotifierProvider<GoogleSignInController, void>(
      GoogleSignInController.new,
    );
