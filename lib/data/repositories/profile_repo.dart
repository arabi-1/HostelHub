import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../supabase_client.dart';

class ProfileRepo {
  final SupabaseClient _client;

  ProfileRepo([SupabaseClient? client]) : _client = client ?? supabaseClient;

  Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final data = profile.toJson();
    data.remove('id'); // ID is immutable primary key
    data.remove('created_at');

    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', profile.id)
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
