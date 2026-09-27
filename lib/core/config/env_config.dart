import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded from `.env`.
///
/// Call [EnvConfig.load] once during app bootstrap (see `main.dart`)
/// before reading any value.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');

  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable "$key". '
        'Check your .env file (see .env.example).',
      );
    }
    return value;
  }
}
