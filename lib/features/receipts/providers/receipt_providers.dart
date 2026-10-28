import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/rent_charge.dart';
import '../../../data/models/resident.dart';
import '../../../data/models/room.dart';
import '../../auth/providers/auth_provider.dart';
import '../../rent/providers/rent_providers.dart';
import '../../rooms/providers/room_providers.dart';

class ReceiptBundle {
  final Payment payment;
  final RentCharge charge;
  final Resident resident;
  final Room? room;
  final String businessName;

  const ReceiptBundle({
    required this.payment,
    required this.charge,
    required this.resident,
    this.room,
    required this.businessName,
  });
}

final receiptBundleProvider =
    FutureProvider.family<ReceiptBundle?, String>((ref, paymentId) async {
  final paymentRepo = ref.watch(paymentRepoProvider);
  final rentRepo = ref.watch(rentRepoProvider);
  final residentRepo = ref.watch(residentRepoProvider);
  final roomRepo = ref.watch(roomRepoProvider);
  final profile = await ref.watch(currentProfileProvider.future);

  final payment = await paymentRepo.getPaymentById(paymentId);
  if (payment == null) return null;

  final charge = await rentRepo.getChargeById(payment.chargeId);
  if (charge == null) return null;

  final resident = await residentRepo.getResidentById(payment.residentId);
  if (resident == null) return null;

  Room? room;
  if (resident.roomId != null) {
    room = await roomRepo.getRoomById(resident.roomId!);
  }

  final bName = profile?.businessName;
  final resolvedBusinessName = (bName != null && bName.trim().isNotEmpty) ? bName.trim() : 'HostelHub';

  return ReceiptBundle(
    payment: payment,
    charge: charge,
    resident: resident,
    room: room,
    businessName: resolvedBusinessName,
  );
});
