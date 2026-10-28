import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/data/models/payment.dart';
import 'package:hostelhub/data/models/rent_charge.dart';
import 'package:hostelhub/data/models/resident.dart';
import 'package:hostelhub/data/models/room.dart';
import 'package:hostelhub/features/receipts/services/pdf_receipt_builder.dart';
import 'package:hostelhub/features/receipts/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleResident = Resident(
    id: 'res-001',
    ownerId: 'owner-001',
    fullName: 'Muhammad Usman',
    phone: '03001234567',
    cnic: '42101-1234567-1',
    guardianName: 'Tariq Usman',
    guardianPhone: '03217654321',
    monthlyRent: 18000,
    securityDeposit: 18000,
    rentDueDay: 5,
    joinDate: DateTime(2026, 1, 1),
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleRoom = Room(
    id: 'room-001',
    ownerId: 'owner-001',
    propertyId: 'prop-001',
    roomNumber: '102-B',
    floor: '1st Floor',
    capacity: 3,
    defaultRent: 18000,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleCharge = RentCharge(
    id: 'charge-001',
    ownerId: 'owner-001',
    residentId: 'res-001',
    period: DateTime(2026, 10, 1),
    amount: 18000,
    dueDate: DateTime(2026, 10, 5),
    paid: 10000,
    balance: 8000,
    createdAt: DateTime(2026, 10, 1),
  );

  final samplePayment = Payment(
    id: 'pay-001',
    ownerId: 'owner-001',
    residentId: 'res-001',
    chargeId: 'charge-001',
    receiptNo: 'RCT-000101',
    amount: 10000,
    method: 'jazzcash',
    paidOn: DateTime(2026, 10, 4),
    note: 'Initial partial payment',
    createdAt: DateTime(2026, 10, 4),
  );

  group('WhatsApp Service Tests (FR-17, FR-18, FR-20)', () {
    test('Builds overdue rent reminder with "was due on" and PKR formatting', () {
      final msg = WhatsAppService.buildReminderMessage(
        residentName: sampleResident.fullName,
        businessName: 'Al-Madina Hostel',
        balance: 8000,
        period: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 5),
        isOverdue: true,
      );

      expect(msg, contains('Assalam o Alaikum Muhammad Usman,'));
      expect(msg, contains('Al-Madina Hostel'));
      expect(msg, contains('Rs 8,000'));
      expect(msg, contains('October 2026'));
      expect(msg, contains('was due on 05 Oct 2026'));
      expect(msg, contains('Kindly pay at your earliest convenience. Thank you.'));
    });

    test('Builds pending rent reminder with "is due on"', () {
      final msg = WhatsAppService.buildReminderMessage(
        residentName: sampleResident.fullName,
        businessName: 'HostelHub',
        balance: 18000,
        period: DateTime(2026, 11, 1),
        dueDate: DateTime(2026, 11, 5),
        isOverdue: false,
      );

      expect(msg, contains('is due on 05 Nov 2026'));
      expect(msg, contains('Rs 18,000'));
    });

    test('Builds standardized payment receipt message', () {
      final msg = WhatsAppService.buildReceiptMessage(
        receiptNo: samplePayment.receiptNo,
        businessName: 'Al-Madina Hostel',
        amount: samplePayment.amount,
        residentName: sampleResident.fullName,
        period: sampleCharge.period,
        paidOn: samplePayment.paidOn,
        method: samplePayment.method,
        balance: sampleCharge.balance,
      );

      expect(msg, contains('Receipt RCT-000101 — Al-Madina Hostel'));
      expect(msg, contains('Received Rs 10,000 from Muhammad Usman'));
      expect(msg, contains('for October 2026'));
      expect(msg, contains('on 04 Oct 2026 via jazzcash.'));
      expect(msg, contains('Remaining balance: Rs 8,000.'));
      expect(msg, contains('Thank you.'));
    });

    test('Builds normalized wa.me URL correctly', () {
      final uri = WhatsAppService.buildWhatsAppUri(
        phone: '03001234567',
        message: 'Hello World',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/923001234567');
      expect(uri.queryParameters['text'], 'Hello World');
    });

    test('CRITICAL SECURITY: WhatsApp messages NEVER include CNIC (Section 8.1)', () {
      final reminder = WhatsAppService.buildReminderMessage(
        residentName: sampleResident.fullName,
        businessName: 'Al-Madina Hostel',
        balance: 8000,
        period: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 5),
        isOverdue: true,
      );

      final receipt = WhatsAppService.buildReceiptMessage(
        receiptNo: samplePayment.receiptNo,
        businessName: 'Al-Madina Hostel',
        amount: samplePayment.amount,
        residentName: sampleResident.fullName,
        period: sampleCharge.period,
        paidOn: samplePayment.paidOn,
        method: samplePayment.method,
        balance: sampleCharge.balance,
      );

      expect(reminder, isNot(contains('42101')));
      expect(reminder, isNot(contains('1234567')));
      expect(receipt, isNot(contains('42101')));
      expect(receipt, isNot(contains('1234567')));
    });
  });

  group('PDF Receipt Builder Tests (FR-19)', () {
    test('Generates valid PDF document byte stream', () async {
      final pdfBytes = await PdfReceiptBuilder.build(
        payment: samplePayment,
        charge: sampleCharge,
        resident: sampleResident,
        room: sampleRoom,
        businessName: 'Al-Madina Hostel',
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files start with the magic header '%PDF-'
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('CRITICAL SECURITY: PDF receipt does NOT leak resident CNIC', () async {
      final pdfBytes = await PdfReceiptBuilder.build(
        payment: samplePayment,
        charge: sampleCharge,
        resident: sampleResident,
        room: sampleRoom,
        businessName: 'Al-Madina Hostel',
      );

      // Search byte stream for CNIC pattern (raw or masked)
      final pdfString = latin1.decode(pdfBytes);
      expect(pdfString, isNot(contains('42101-1234567-1')));
      expect(pdfString, isNot(contains('4210112345671')));
    });

    test('Builds PDF receipt when room is unassigned and balance is zero', () async {
      final fullyPaidCharge = RentCharge(
        id: 'charge-002',
        ownerId: 'owner-001',
        residentId: 'res-001',
        period: DateTime(2026, 10, 1),
        amount: 18000,
        dueDate: DateTime(2026, 10, 5),
        paid: 18000,
        balance: 0,
        createdAt: DateTime(2026, 10, 1),
      );

      final fullPayment = Payment(
        id: 'pay-002',
        ownerId: 'owner-001',
        residentId: 'res-001',
        chargeId: 'charge-002',
        receiptNo: 'RCT-000102',
        amount: 18000,
        method: 'cash',
        paidOn: DateTime(2026, 10, 5),
        createdAt: DateTime(2026, 10, 5),
      );

      final pdfBytes = await PdfReceiptBuilder.build(
        payment: fullPayment,
        charge: fullyPaidCharge,
        resident: sampleResident,
        room: null,
        businessName: '',
      );

      expect(pdfBytes, isNotEmpty);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
