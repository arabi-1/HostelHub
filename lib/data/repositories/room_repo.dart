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

    if (data['property_id'] == null || (data['property_id'] is String && (data['property_id'] as String).trim().isEmpty)) {
      throw ArgumentError('property_id must be a valid non-empty UUID');
    }

    final currentUserId = _effectiveClient.auth.currentUser?.id;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      data['owner_id'] = currentUserId;
    } else if (data['owner_id'] == null || (data['owner_id'] is String && (data['owner_id'] as String).trim().isEmpty)) {
      data.remove('owner_id');
    }

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

    if (data['property_id'] == null || (data['property_id'] is String && (data['property_id'] as String).trim().isEmpty)) {
      throw ArgumentError('property_id must be a valid non-empty UUID');
    }

    final currentUserId = _effectiveClient.auth.currentUser?.id;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      data['owner_id'] = currentUserId;
    } else if (data['owner_id'] == null || (data['owner_id'] is String && (data['owner_id'] as String).trim().isEmpty)) {
      data.remove('owner_id');
    }

    final response = await _effectiveClient
        .from('rooms')
        .update(data)
        .eq('id', room.id)
        .select()
        .single();

    return Room.fromJson(response);
  }
}
