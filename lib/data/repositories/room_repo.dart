import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room.dart';
import '../supabase_client.dart';

class RoomRepo {
  final SupabaseClient? _client;

  RoomRepo([SupabaseClient? client]) : _client = client;

  SupabaseClient get _effectiveClient => _client ?? supabaseClient;

  Future<List<Room>> getRooms(String propertyId, {bool activeOnly = true}) async {
    var query = _effectiveClient.from('rooms').select().eq('property_id', propertyId);
    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    final response = await query.order('room_number');
    return (response as List<dynamic>)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Room>> getAllRooms({bool activeOnly = true}) async {
    var query = _effectiveClient.from('rooms').select();
    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    final response = await query.order('room_number');
    return (response as List<dynamic>)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Room?> getRoomById(String roomId) async {
    final response = await _effectiveClient
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) return null;
    return Room.fromJson(response);
  }

  Future<Room> createRoom(Room room) async {
    final data = room.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _effectiveClient
        .from('rooms')
        .insert(data)
        .select()
        .single();

    return Room.fromJson(response);
  }

  Future<Room> updateRoom(Room room) async {
    final data = room.toJson();
    data.remove('id');
    data.remove('created_at');

    final response = await _effectiveClient
        .from('rooms')
        .update(data)
        .eq('id', room.id)
        .select()
        .single();

    return Room.fromJson(response);
  }
}
