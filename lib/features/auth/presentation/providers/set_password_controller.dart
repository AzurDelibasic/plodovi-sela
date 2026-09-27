import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class SetPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String password) async {
    state = const AsyncLoading();
    final useCase = ref.read(setPasswordUseCaseProvider);
    final result = await useCase(password);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

final setPasswordControllerProvider =
    AsyncNotifierProvider<SetPasswordController, void>(
      SetPasswordController.new,
    );
