import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the initialized [SupabaseClient] singleton to the rest of the
/// app. `Supabase.initialize` must have run in `main.dart` before any
/// provider that depends on this is read.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
