import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident.dart';
import '../supabase_client.dart';

class ResidentRepo {
  final SupabaseClient _client;

  ResidentRepo([SupabaseClient? client]) : _client = client ?? supabaseClient;

  Future<List<Resident>> getResidents({bool activeOnly = true}) async {
    var query = _client.from('residents').select();
    if (activeOnly) {
      query = query.eq('status', 'active');
    }
    final response = await query.order('full_name');
    return (response as List<dynamic>)
        .map((e) => Resident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Resident?> getResidentById(String residentId) async {
    final response = await _client
        .from('residents')
        .select()
        .eq('id', residentId)
        .maybeSingle();

    if (response == null) return null;
    return Resident.fromJson(response);
  }

  Future<Resident> createResident(Resident resident) async {
    final data = resident.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _client
        .from('residents')
        .insert(data)
        .select()
        .single();

    return Resident.fromJson(response);
  }

  Future<Resident> updateResident(Resident resident) async {
    final data = resident.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _client
        .from('residents')
        .update(data)
        .eq('id', resident.id)
        .select()
        .single();

    return Resident.fromJson(response);
  }

  Future<void> markResidentLeft(String residentId, DateTime leftDate) async {
    await _client.from('residents').update({
      'status': 'left',
      'left_date': leftDate.toIso8601String().substring(0, 10),
    }).eq('id', residentId);
  }
}
