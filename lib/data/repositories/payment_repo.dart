import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/rent_status.dart';
import '../models/payment.dart';
import '../supabase_client.dart';

class PaymentRepo {
  final SupabaseClient? _client;

  PaymentRepo([SupabaseClient? client]) : _client = client;

  SupabaseClient get _effectiveClient => _client ?? supabaseClient;

  Future<List<Payment>> getPaymentsForCharge(String chargeId) async {
    final response = await _effectiveClient
        .from('payments')
        .select()
        .eq('charge_id', chargeId)
        .order('paid_on', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> getPaymentsForResident(String residentId) async {
    final response = await _effectiveClient
        .from('payments')
        .select()
        .eq('resident_id', residentId)
        .order('paid_on', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Payment?> getPaymentById(String paymentId) async {
    final response = await _effectiveClient
        .from('payments')
        .select()
        .eq('id', paymentId)
        .maybeSingle();

    if (response == null) return null;
    return Payment.fromJson(response);
  }

  Future<Payment> recordPayment(Payment payment) async {
    final data = payment.toJson();
    data.remove('id');
    data.remove('created_at');
    if (payment.receiptNo.isEmpty) {
      data.remove('receipt_no'); // Database sequence generates RCT-XXXXXX
    }

    final currentUserId = _effectiveClient.auth.currentUser?.id;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      data['owner_id'] = currentUserId;
    } else if (data['owner_id'] == null || (data['owner_id'] is String && (data['owner_id'] as String).trim().isEmpty)) {
      data.remove('owner_id');
    }

    final response = await _effectiveClient
        .from('payments')
        .insert(data)
        .select()
        .single();

    return Payment.fromJson(response);
  }

  /// Fetches the most recent payments with resident information.
  Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 5}) async {
    try {
      final response = await _effectiveClient
          .from('payments')
          .select('*, residents(full_name)')
          .order('paid_on', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      // Fallback without join
      final response = await _effectiveClient
          .from('payments')
          .select()
          .order('paid_on', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    }
  }

  /// Updates an existing payment record within 24 hours of creation (FR-16).
  Future<Payment> updatePayment(Payment payment) async {
    if (!RentStatusUtils.canEditPayment(payment.createdAt)) {
      throw Exception('Payments can only be edited within 24 hours of creation.');
    }

    final data = {
      'amount': payment.amount,
      'method': payment.method,
      'paid_on': payment.paidOn.toIso8601String().substring(0, 10),
      'note': payment.note,
    };

    final response = await _effectiveClient
        .from('payments')
        .update(data)
        .eq('id', payment.id)
        .select()
        .single();

    return Payment.fromJson(response);
  }

  /// Deletes a payment record within 24 hours of creation (FR-16).
  Future<void> deletePayment(String paymentId, DateTime createdAt) async {
    if (!RentStatusUtils.canEditPayment(createdAt)) {
      throw Exception('Payments can only be deleted within 24 hours of creation.');
    }

    await _effectiveClient.from('payments').delete().eq('id', paymentId);
  }
}
