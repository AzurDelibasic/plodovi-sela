/// Maps Supabase Auth's raw (English, technical) error messages to short,
/// user-facing messages. Falls back to a generic message for anything
/// unrecognized, so a raw stack-trace-like string never reaches the UI.
String translateAuthError(String rawMessage) {
  final message = rawMessage.toLowerCase();

  if (message.contains('invalid login credentials') ||
      message.contains('invalid_credentials')) {
    return 'Pogrešan e-mail ili lozinka.';
  }
  if (message.contains('email not confirmed')) {
    return 'Molimo potvrdite vaš e-mail prije prijave — provjerite inbox.';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered') ||
      message.contains('already exists')) {
    return 'Nalog sa ovim e-mailom već postoji. Probajte se prijaviti.';
  }
  if (message.contains('password should be at least') ||
      message.contains('password is too short')) {
    return 'Lozinka mora imati najmanje 6 karaktera.';
  }
  if (message.contains('unable to validate email address') ||
      message.contains('is invalid') && message.contains('email')) {
    return 'Unesite validnu e-mail adresu.';
  }
  if (message.contains('for security purposes') ||
      message.contains('rate limit') ||
      message.contains('too many requests')) {
    return 'Previše pokušaja u kratkom vremenu. Sačekajte malo pa probajte ponovo.';
  }
  if (message.contains('user not found')) {
    return 'Ne postoji nalog sa ovim e-mailom.';
  }
  if (message.contains('network') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection')) {
    return 'Nema internet konekcije. Provjerite mrežu i pokušajte ponovo.';
  }
  if (message.contains('token has expired') || message.contains('expired')) {
    return 'Link je istekao. Zatražite novi.';
  }

  return 'Nešto je pošlo po zlu. Pokušajte ponovo.';
}
