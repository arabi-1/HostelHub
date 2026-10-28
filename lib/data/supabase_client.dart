import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';

SupabaseClient get supabaseClient => Supabase.instance.client;

SupabaseClient? get supabaseClientOrNull {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

Future<void> initializeSupabase() async {
  if (!Env.isConfigured) {
    if (kDebugMode) {
      debugPrint('Supabase is not configured. Missing SUPABASE_URL or SUPABASE_ANON_KEY.');
    }
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
  );
}
