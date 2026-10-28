import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rent_charge.dart';
import '../supabase_client.dart';

class RentRepo {
  final SupabaseClient _client;

  RentRepo([SupabaseClient? client]) : _client = client ?? supabaseClient;

  Future<List<RentCharge>> getChargesForMonth(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10);
    final response = await _client
        .from('charge_balances')
        .select()
        .eq('period', firstDay)
        .order('due_date');

    return (response as List<dynamic>)
        .map((e) => RentCharge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RentCharge>> getChargesForResident(String residentId) async {
    final response = await _client
        .from('charge_balances')
        .select()
        .eq('resident_id', residentId)
        .order('period', ascending: false);

    return (response as List<dynamic>)
        .map((e) => RentCharge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> generateMonthlyCharges(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final periodStr = firstDay.toIso8601String().substring(0, 10);

    // Fetch active residents
    final residentsRes = await _client
        .from('residents')
        .select('id, monthly_rent, rent_due_day, join_date')
        .eq('status', 'active');

    final activeResidents = residentsRes as List<dynamic>;

    final chargesToInsert = <Map<String, dynamic>>[];
    for (final r in activeResidents) {
      final joinDate = DateTime.parse(r['join_date'] as String);
      final joinMonth = DateTime(joinDate.year, joinDate.month, 1);

      // Only generate if current period >= join_date month
      if (firstDay.isBefore(joinMonth)) continue;

      final dueDay = (r['rent_due_day'] as int?) ?? 5;
      final dueDate = DateTime(month.year, month.month, dueDay);

      chargesToInsert.add({
        'resident_id': r['id'],
        'period': periodStr,
        'amount': r['monthly_rent'],
        'due_date': dueDate.toIso8601String().substring(0, 10),
      });
    }

    if (chargesToInsert.isNotEmpty) {
      // Upsert with ignoreDuplicates: true
      await _client.from('rent_charges').upsert(
            chargesToInsert,
            onConflict: 'resident_id,period',
            ignoreDuplicates: true,
          );
    }
  }
}
