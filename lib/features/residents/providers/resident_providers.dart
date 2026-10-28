import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/resident.dart';
import '../../../data/models/room.dart';
import '../../rooms/providers/room_providers.dart';

// Resident Filter: 'active', 'left', 'all'
class ResidentFilterNotifier extends Notifier<String> {
  @override
  String build() => 'active';

  void setFilter(String filter) {
    state = filter;
  }
}

final residentFilterProvider =
    NotifierProvider<ResidentFilterNotifier, String>(ResidentFilterNotifier.new);

// Resident Search Query
class ResidentSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final residentSearchQueryProvider =
    NotifierProvider<ResidentSearchQueryNotifier, String>(ResidentSearchQueryNotifier.new);

// Residents AsyncNotifier
class ResidentsNotifier extends AsyncNotifier<List<Resident>> {
  @override
  Future<List<Resident>> build() async {
    final repo = ref.watch(residentRepoProvider);
    // Fetch all residents (both active and left) so filtering is instant in memory
    return repo.getResidents(activeOnly: false);
  }

  Future<Resident> addResident({
    String? roomId,
    required String fullName,
    required String phone,
    String? cnic,
    String? guardianName,
    String? guardianPhone,
    required double monthlyRent,
    double securityDeposit = 0.0,
    int rentDueDay = 5,
    required DateTime joinDate,
    String? notes,
  }) async {
    final repo = ref.read(residentRepoProvider);
    final newResident = Resident(
      id: '',
      ownerId: '',
      roomId: roomId,
      fullName: fullName.trim(),
      phone: phone.trim(),
      cnic: cnic?.trim().isEmpty == true ? null : cnic?.trim(),
      guardianName: guardianName?.trim().isEmpty == true ? null : guardianName?.trim(),
      guardianPhone: guardianPhone?.trim().isEmpty == true ? null : guardianPhone?.trim(),
      monthlyRent: monthlyRent,
      securityDeposit: securityDeposit,
      rentDueDay: rentDueDay,
      joinDate: joinDate,
      status: 'active',
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final created = await repo.createResident(newResident);
      ref.invalidateSelf();
      ref.invalidate(roomOccupancyProvider);
      return created;
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('room is full') || e.code == 'P0001') {
        throw Exception('Selected room is full. Please pick another room.');
      }
      rethrow;
    }
  }

  Future<Resident> updateResident(Resident resident) async {
    final repo = ref.read(residentRepoProvider);
    try {
      final updated = await repo.updateResident(resident);
      ref.invalidateSelf();
      ref.invalidate(roomOccupancyProvider);
      return updated;
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('room is full') || e.code == 'P0001') {
        throw Exception('Selected room is full. Please pick another room.');
      }
      rethrow;
    }
  }

  Future<void> markResidentLeft(String residentId, DateTime leftDate) async {
    final repo = ref.read(residentRepoProvider);
    await repo.markResidentLeft(residentId, leftDate);
    ref.invalidateSelf();
    ref.invalidate(roomOccupancyProvider);
  }
}

final residentsProvider =
    AsyncNotifierProvider<ResidentsNotifier, List<Resident>>(ResidentsNotifier.new);

// Single Resident Provider by ID
final residentDetailProvider =
    FutureProvider.family<Resident?, String>((ref, residentId) async {
  final residents = await ref.watch(residentsProvider.future);
  try {
    return residents.firstWhere((r) => r.id == residentId);
  } catch (_) {
    final repo = ref.watch(residentRepoProvider);
    return repo.getResidentById(residentId);
  }
});

// Filtered and Searched Residents Provider
final filteredResidentsProvider = Provider<AsyncValue<List<Resident>>>((ref) {
  final residentsAsync = ref.watch(residentsProvider);
  final filter = ref.watch(residentFilterProvider);
  final query = ref.watch(residentSearchQueryProvider).toLowerCase().trim();
  final roomsAsync = ref.watch(roomsProvider);

  return residentsAsync.whenData((residents) {
    // 1. Status Filter
    var list = residents;
    if (filter == 'active') {
      list = list.where((r) => r.status == 'active').toList();
    } else if (filter == 'left') {
      list = list.where((r) => r.status == 'left').toList();
    }

    // 2. Search Query (Name, Phone, Room Number)
    if (query.isNotEmpty) {
      final roomsMap = <String, Room>{};
      final roomsList = roomsAsync.value ?? [];
      for (final rm in roomsList) {
        roomsMap[rm.id] = rm;
      }

      list = list.where((r) {
        final matchesName = r.fullName.toLowerCase().contains(query);
        final matchesPhone = r.phone.contains(query);
        final roomNumber = r.roomId != null ? (roomsMap[r.roomId]?.roomNumber ?? '') : '';
        final matchesRoom = roomNumber.toLowerCase().contains(query);
        return matchesName || matchesPhone || matchesRoom;
      }).toList();
    }

    return list;
  });
});

// Available Rooms Provider for room picker (rooms with free beds + resident's current room)
final availableRoomsProvider =
    Provider.family<List<Room>, String?>((ref, currentRoomId) {
  final rooms = ref.watch(roomsProvider).value ?? [];
  final occupancy = ref.watch(roomOccupancyProvider).value ?? {};

  return rooms.where((room) {
    if (currentRoomId != null && room.id == currentRoomId) {
      return true; // current room is always selectable
    }
    final occupied = occupancy[room.id] ?? 0;
    final freeBeds = room.capacity - occupied;
    return freeBeds > 0;
  }).toList();
});
