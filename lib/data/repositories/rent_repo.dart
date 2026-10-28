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

  /// Queries the dashboard_summary RPC or computes aggregations from tables.
  Future<Map<String, dynamic>> getDashboardSummary([DateTime? month]) async {
    final period = RentStatusUtils.getPeriodForMonth(month ?? DateTime.now());
    final periodStr = period.toIso8601String().substring(0, 10);

    try {
      final rpcRes = await _effectiveClient.rpc(
        'dashboard_summary',
        params: {'p_month': periodStr},
      );
      if (rpcRes != null && rpcRes is Map<String, dynamic>) {
        return rpcRes;
      }
    } catch (_) {
      // Fallback to client-side direct table queries
    }

    try {
      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);
      final startOfMonth = DateTime(period.year, period.month, 1).toIso8601String().substring(0, 10);
      final nextMonth = DateTime(period.year, period.month + 1, 1);
      final endOfMonth = nextMonth.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      final chargesRes = await _effectiveClient
          .from('charge_balances')
          .select('amount, balance, due_date')
          .eq('period', periodStr);

      double billed = 0.0;
      double pending = 0.0;
      for (final c in (chargesRes as List<dynamic>)) {
        final amt = (c['amount'] as num?)?.toDouble() ?? 0.0;
        final bal = (c['balance'] as num?)?.toDouble() ?? 0.0;
        billed += amt;
        if (bal > 0) pending += bal;
      }

      final overdueRes = await _effectiveClient
          .from('charge_balances')
          .select('balance')
          .gt('balance', 0)
          .lt('due_date', todayStr);

      double overdue = 0.0;
      for (final c in (overdueRes as List<dynamic>)) {
        overdue += (c['balance'] as num?)?.toDouble() ?? 0.0;
      }

      final paymentsRes = await _effectiveClient
          .from('payments')
          .select('amount')
          .gte('paid_on', startOfMonth)
          .lte('paid_on', endOfMonth);

      double collected = 0.0;
      for (final p in (paymentsRes as List<dynamic>)) {
        collected += (p['amount'] as num?)?.toDouble() ?? 0.0;
      }

      final roomsRes = await _effectiveClient
          .from('rooms')
          .select('capacity')
          .eq('is_active', true);

      int bedsTotal = 0;
      for (final r in (roomsRes as List<dynamic>)) {
        bedsTotal += (r['capacity'] as num?)?.toInt() ?? 0;
      }

      final residentsRes = await _effectiveClient
          .from('residents')
          .select('room_id')
          .eq('status', 'active');

      final activeResidents = (residentsRes as List<dynamic>).length;
      int bedsOccupied = 0;
      for (final res in (residentsRes as List<dynamic>)) {
        if (res['room_id'] != null) {
          bedsOccupied++;
        }
      }

      return {
        'billed': billed,
        'collected': collected,
        'pending': pending,
        'overdue': overdue,
        'beds_total': bedsTotal,
        'beds_occupied': bedsOccupied,
        'active_residents': activeResidents,
      };
    } catch (_) {
      return {
        'billed': 0.0,
        'collected': 0.0,
        'pending': 0.0,
        'overdue': 0.0,
        'beds_total': 0,
        'beds_occupied': 0,
        'active_residents': 0,
      };
    }
  }
}
