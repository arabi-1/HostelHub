import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';
import '../supabase_client.dart';

class PropertyRepo {
  final SupabaseClient _client;

  PropertyRepo([SupabaseClient? client]) : _client = client ?? supabaseClient;

  Future<List<Property>> getProperties({bool activeOnly = true}) async {
    var query = _client.from('properties').select();
    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    final response = await query.order('name');
    return (response as List<dynamic>)
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Property> createProperty(Property property) async {
    final data = property.toJson();
    data.remove('id'); // let Postgres generate UUID
    data.remove('created_at');

    final response = await _client
        .from('properties')
        .insert(data)
        .select()
        .single();

    return Property.fromJson(response);
  }

  Future<Property> updateProperty(Property property) async {
    final data = property.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _client
        .from('properties')
        .update(data)
        .eq('id', property.id)
        .select()
        .single();

    return Property.fromJson(response);
  }

  Future<void> archiveProperty(String propertyId) async {
    await _client
        .from('properties')
        .update({'is_active': false})
        .eq('id', propertyId);
  }
}
