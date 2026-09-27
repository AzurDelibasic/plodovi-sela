/// Mirrors the `public.app_role` Postgres enum
/// (see supabase/migrations/20250101000000_roles_and_profiles.sql).
enum AppRole {
  kupac,
  prodavac,
  admin;

  static AppRole fromDb(String value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.kupac,
    );
  }
}

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.kupac:
        return 'Kupac';
      case AppRole.prodavac:
        return 'Prodavac';
      case AppRole.admin:
        return 'Administrator';
    }
  }
}
