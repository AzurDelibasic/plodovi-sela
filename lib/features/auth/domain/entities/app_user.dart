import 'package:equatable/equatable.dart';

import 'app_role.dart';

/// The authenticated user, as seen by the domain/presentation layers.
///
/// Deliberately decoupled from Supabase's `User` type — the domain layer
/// must not depend on a specific backend SDK.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.hasPasswordIdentity,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.cityId,
    this.cityName,
  });

  final String id;
  final String email;
  final AppRole role;
  final String? fullName;

  /// Storefront fields — only meaningful for a `prodavac` ("farm"), but
  /// harmless to carry on every user.
  final String? avatarUrl;
  final String? bio;
  final int? cityId;
  final String? cityName;

  /// Whether this account can sign in with e-mail + password. `false` for
  /// an account created purely through Google — the router forces those
  /// users through `/set-password` once, so every account ends up with
  /// both sign-in methods and there's never more than one profile per
  /// e-mail address.
  final bool hasPasswordIdentity;

  @override
  List<Object?> get props => [
    id,
    email,
    role,
    fullName,
    avatarUrl,
    bio,
    cityId,
    cityName,
    hasPasswordIdentity,
  ];
}
