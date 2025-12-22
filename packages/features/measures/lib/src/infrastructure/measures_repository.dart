import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeasuresRepository {
  final SupabaseClient _supabase;

  MeasuresRepository(this._supabase);

  // --- Measures ---

  // Real-time stream for measures
  Stream<List<Map<String, dynamic>>> getMeasures() {
     return _supabase
        .from('measures')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> createMeasure(String name) async {
    await _supabase.from('measures').insert({'name': name});
  }

  Future<void> updateMeasure(String id, String name) async {
    await _supabase.from('measures').update({'name': name}).eq('id', id);
  }

  Future<void> deleteMeasure(String id) async {
    await _supabase.from('measures').delete().eq('id', id);
  }
}

final measuresRepositoryProvider = Provider<MeasuresRepository>((ref) {
  return MeasuresRepository(Supabase.instance.client);
});

final measuresProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(measuresRepositoryProvider).getMeasures();
});
