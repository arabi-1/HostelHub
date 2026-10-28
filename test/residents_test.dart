import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/core/utils/cnic.dart';
import 'package:hostelhub/core/utils/phone.dart';
import 'package:hostelhub/data/models/resident.dart';
import 'package:hostelhub/data/models/room.dart';

void main() {
  group('PhoneUtils Tests', () {
    test('Normalizes various Pakistani phone formats to 923XXXXXXXXX', () {
      expect(PhoneUtils.normalize('03001234567'), '923001234567');
      expect(PhoneUtils.normalize('+923001234567'), '923001234567');
      expect(PhoneUtils.normalize('923001234567'), '923001234567');
      expect(PhoneUtils.normalize('0300-1234567'), '923001234567');
      expect(PhoneUtils.normalize('0300 123 4567'), '923001234567');
      expect(PhoneUtils.normalize('3001234567'), '923001234567');
    });

    test('Validates Pakistani phone numbers correctly', () {
      expect(PhoneUtils.isValid('03001234567'), isTrue);
      expect(PhoneUtils.isValid('+923219876543'), isTrue);
      expect(PhoneUtils.isValid('923455555555'), isTrue);

      // Invalid cases
      expect(PhoneUtils.isValid('0300123456'), isFalse); // too short
      expect(PhoneUtils.isValid('04231234567'), isFalse); // landline
      expect(PhoneUtils.isValid('12345'), isFalse);
      expect(PhoneUtils.isValid(''), isFalse);
    });

    test('Formats normalized numbers for local display as 03XX XXXXXXX', () {
      expect(PhoneUtils.formatDisplay('923001234567'), '0300 1234567');
      expect(PhoneUtils.formatDisplay('+923219876543'), '0321 9876543');
      expect(PhoneUtils.formatDisplay('03451122334'), '0345 1122334');
    });
  });

  group('CnicUtils Tests', () {
    test('Validates 13-digit Pakistani CNIC', () {
      expect(CnicUtils.isValid('3520112345671'), isTrue);
      expect(CnicUtils.isValid('35201-1234567-1'), isTrue);

      // Invalid cases
      expect(CnicUtils.isValid('352011234567'), isFalse); // 12 digits
      expect(CnicUtils.isValid('35201123456712'), isFalse); // 14 digits
      expect(CnicUtils.isValid('abc'), isFalse);
      expect(CnicUtils.isValid(''), isFalse);
    });

    test('Formats CNIC to XXXXX-XXXXXXX-X', () {
      expect(CnicUtils.format('3520112345671'), '35201-1234567-1');
    });

    test('Masks CNIC properly as •••••-•••••XX-X', () {
      expect(CnicUtils.mask('3520112345671'), '•••••-•••••67-1');
      expect(CnicUtils.mask('35201-1234567-1'), '•••••-•••••67-1');
    });
  });

  group('Resident Bed Capacity & Left Flow Tests', () {
    final room = Room(
      id: 'room-101',
      ownerId: 'owner-1',
      propertyId: 'prop-1',
      roomNumber: '101',
      capacity: 2,
      defaultRent: 12000,
      createdAt: DateTime.now(),
    );

    final res1 = Resident(
      id: 'res-1',
      ownerId: 'owner-1',
      roomId: 'room-101',
      fullName: 'Resident One',
      phone: '923001111111',
      monthlyRent: 12000,
      joinDate: DateTime(2026, 1, 1),
      status: 'active',
      createdAt: DateTime.now(),
    );

    final res2 = Resident(
      id: 'res-2',
      ownerId: 'owner-1',
      roomId: 'room-101',
      fullName: 'Resident Two',
      phone: '923002222222',
      monthlyRent: 12000,
      joinDate: DateTime(2026, 1, 1),
      status: 'active',
      createdAt: DateTime.now(),
    );

    test('Full room has 0 available beds with 2 active residents', () {
      final residents = [res1, res2];
      final activeResidents = residents.where((r) => r.status == 'active').toList();
      final occupiedCount = activeResidents.where((r) => r.roomId == room.id).length;
      final freeBeds = room.capacity - occupiedCount;

      expect(occupiedCount, 2);
      expect(freeBeds, 0);
    });

    test('Marking resident as left frees bed immediately', () {
      final leftRes2 = res2.copyWith(status: 'left', leftDate: DateTime.now());
      final residents = [res1, leftRes2];

      final activeResidents = residents.where((r) => r.status == 'active').toList();
      final occupiedCount = activeResidents.where((r) => r.roomId == room.id).length;
      final freeBeds = room.capacity - occupiedCount;

      expect(occupiedCount, 1);
      expect(freeBeds, 1); // Bed is now freed for new residents!
      expect(leftRes2.status, 'left');
      expect(leftRes2.leftDate, isNotNull);
    });
  });
}
