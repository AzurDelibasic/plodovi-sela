import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/app_role.dart';
import '../../domain/entities/app_user.dart';

/// Maps a Supabase [supabase.User] (+ its `public.profiles` row) to the
/// domain [AppUser].
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.hasPasswordIdentity,
    super.fullName,
    super.avatarUrl,
    super.bio,
    super.cityId,
    super.cityName,
  });

  factory AppUserModel.fromSupabaseUser(
    supabase.User user, {
    required AppRole role,
    String? fullName,
  }) {
    return AppUserModel(
      id: user.id,
      email: user.email ?? '',
      role: role,
      hasPasswordIdentity:
          user.identities?.any((identity) => identity.provider == 'email') ??
          false,
      fullName: fullName ?? user.userMetadata?['full_name'] as String?,
    );
  }
}
