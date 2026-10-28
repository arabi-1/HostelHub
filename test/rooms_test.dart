import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/data/models/property.dart';
import 'package:hostelhub/data/models/resident.dart';
import 'package:hostelhub/data/models/room.dart';

void main() {
  group('Occupancy and Vacancy Calculations', () {
    final testRooms = [
      Room(
        id: 'room-1',
        ownerId: 'owner-1',
        propertyId: 'prop-1',
        roomNumber: '101',
        capacity: 4,
        defaultRent: 10000,
        createdAt: DateTime.now(),
      ),
      Room(
        id: 'room-2',
        ownerId: 'owner-1',
        propertyId: 'prop-1',
        roomNumber: '102',
        capacity: 2,
        defaultRent: 12000,
        createdAt: DateTime.now(),
      ),
      Room(
        id: 'room-3',
        ownerId: 'owner-1',
        propertyId: 'prop-1',
        roomNumber: '103',
        capacity: 1,
        defaultRent: 18000,
        createdAt: DateTime.now(),
      ),
    ];

    final testResidents = [
      Resident(
        id: 'res-1',
        ownerId: 'owner-1',
        roomId: 'room-1',
        fullName: 'Resident One',
        phone: '923001111111',
        monthlyRent: 10000,
        joinDate: DateTime(2026, 1, 1),
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Resident(
        id: 'res-2',
        ownerId: 'owner-1',
        roomId: 'room-1',
        fullName: 'Resident Two',
        phone: '923002222222',
        monthlyRent: 10000,
        joinDate: DateTime(2026, 1, 1),
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Resident(
        id: 'res-3',
        ownerId: 'owner-1',
        roomId: 'room-2',
        fullName: 'Resident Three',
        phone: '923003333333',
        monthlyRent: 12000,
        joinDate: DateTime(2026, 1, 1),
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Resident(
        id: 'res-4',
        ownerId: 'owner-1',
        roomId: 'room-2',
        fullName: 'Resident Four',
        phone: '923004444444',
        monthlyRent: 12000,
        joinDate: DateTime(2026, 1, 1),
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Resident(
        id: 'res-left',
        ownerId: 'owner-1',
        roomId: 'room-3',
        fullName: 'Former Resident',
        phone: '923005555555',
        monthlyRent: 18000,
        joinDate: DateTime(2026, 1, 1),
        status: 'left', // Should NOT count towards occupancy
        createdAt: DateTime.now(),
      ),
    ];

    test('Occupancy count accurately maps active residents to room IDs', () {
      final activeResidents = testResidents.where((r) => r.status == 'active').toList();
      final Map<String, int> occupancyMap = {};
      for (final r in activeResidents) {
        if (r.roomId != null && r.roomId!.isNotEmpty) {
          occupancyMap[r.roomId!] = (occupancyMap[r.roomId!] ?? 0) + 1;
        }
      }

      expect(occupancyMap['room-1'], 2); // 2 active
      expect(occupancyMap['room-2'], 2); // 2 active (full)
      expect(occupancyMap['room-3'], isNull); // 0 active (the only resident left)
    });

    test('Vacancy filter retains only rooms with available beds', () {
      final activeResidents = testResidents.where((r) => r.status == 'active').toList();
      final Map<String, int> occupancyMap = {};
      for (final r in activeResidents) {
        if (r.roomId != null && r.roomId!.isNotEmpty) {
          occupancyMap[r.roomId!] = (occupancyMap[r.roomId!] ?? 0) + 1;
        }
      }

      // Filter vacant rooms
      final vacantRooms = testRooms.where((room) {
        final occupied = occupancyMap[room.id] ?? 0;
        final freeBeds = room.capacity - occupied;
        return freeBeds > 0;
      }).toList();

      expect(vacantRooms.length, 2);
      expect(vacantRooms.any((r) => r.id == 'room-1'), isTrue); // 4 cap, 2 occupied -> 2 free
      expect(vacantRooms.any((r) => r.id == 'room-2'), isFalse); // 2 cap, 2 occupied -> 0 free (FULL)
      expect(vacantRooms.any((r) => r.id == 'room-3'), isTrue); // 1 cap, 0 occupied -> 1 free
    });

    test('Room duplicate error message formatter produces clear user message', () {
      String formatDuplicateError(String roomNumber) {
        return 'Room "$roomNumber" already exists in this property.';
      }

      expect(
        formatDuplicateError('101'),
        'Room "101" already exists in this property.',
      );
    });

    test('Property archive sets isActive to false', () {
      final prop = Property(
        id: 'prop-1',
        ownerId: 'owner-1',
        name: 'Main Branch',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final archived = prop.copyWith(isActive: false);
      expect(archived.isActive, isFalse);
      expect(archived.name, 'Main Branch');
    });
  });
}
