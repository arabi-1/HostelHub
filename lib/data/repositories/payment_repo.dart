import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<Payment> recordPayment(Payment payment) async {
    final data = payment.toJson();
    data.remove('id');
    data.remove('created_at');
    if (payment.receiptNo.isEmpty) {
      data.remove('receipt_no'); // let sequence default generate RCT-XXXXXX
    }

    final response = await _effectiveClient
        .from('payments')
        .insert(data)
        .select()
        .single();

    return Payment.fromJson(response);
  }
}
