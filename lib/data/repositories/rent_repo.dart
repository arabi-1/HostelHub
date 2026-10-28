import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/rent_status.dart';
import '../models/rent_charge.dart';
import '../supabase_client.dart';

class RentRepo {
  final SupabaseClient? _client;

  RentRepo([SupabaseClient? client]) : _client = client;

  SupabaseClient get _effectiveClient => _client ?? supabaseClient;

  Future<List<RentCharge>> getChargesForMonth(DateTime month) async {
    final periodDate = RentStatusUtils.getPeriodForMonth(month);
    final periodStr = periodDate.toIso8601String().substring(0, 10);

    final response = await _effectiveClient
        .from('charge_balances')
        .select()
        .eq('period', periodStr)
        .order('due_date');

    return (response as List<dynamic>)
        .map((e) => RentCharge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RentCharge>> getChargesForResident(String residentId) async {
    final response = await _effectiveClient
        .from('charge_balances')
        .select()
        .eq('resident_id', residentId)
        .order('period', ascending: false);

    return (response as List<dynamic>)
        .map((e) => RentCharge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RentCharge?> getChargeById(String chargeId) async {
    final response = await _effectiveClient
        .from('charge_balances')
        .select()
        .eq('id', chargeId)
        .maybeSingle();

    if (response == null) return null;
    return RentCharge.fromJson(response);
  }

  /// Automatically generates monthly rent charges for active residents for [month].
  /// Idempotent: ignores duplicates on (resident_id, period).
  Future<void> generateMonthlyCharges(DateTime month) async {
    final firstDay = RentStatusUtils.getPeriodForMonth(month);
    final periodStr = firstDay.toIso8601String().substring(0, 10);

    // Fetch active residents
    final residentsRes = await _effectiveClient
        .from('residents')
        .select('id, monthly_rent, rent_due_day, join_date, status, left_date')
        .eq('status', 'active');

    final activeResidents = residentsRes as List<dynamic>;

    final chargesToInsert = <Map<String, dynamic>>[];
    for (final r in activeResidents) {
      final joinDate = DateTime.parse(r['join_date'] as String);
      final joinMonth = RentStatusUtils.getPeriodForMonth(joinDate);

      // Only generate if current period >= join_date's month
      if (firstDay.isBefore(joinMonth)) continue;

      // If resident left, do not generate for periods after left_date's month
      if (r['left_date'] != null) {
        final leftDate = DateTime.parse(r['left_date'] as String);
        final leftMonth = RentStatusUtils.getPeriodForMonth(leftDate);
        if (firstDay.isAfter(leftMonth)) continue;
      }

      final dueDay = (r['rent_due_day'] as int?) ?? 5;
      final dueDate = RentStatusUtils.calculateDueDate(
        period: firstDay,
        rentDueDay: dueDay,
      );

      chargesToInsert.add({
        'resident_id': r['id'],
        'period': periodStr,
        'amount': (r['monthly_rent'] as num).toDouble(),
        'due_date': dueDate.toIso8601String().substring(0, 10),
      });
    }

    if (chargesToInsert.isNotEmpty) {
      await _effectiveClient.from('rent_charges').upsert(
            chargesToInsert,
            onConflict: 'resident_id,period',
            ignoreDuplicates: true,
          );
    }
  }
}
