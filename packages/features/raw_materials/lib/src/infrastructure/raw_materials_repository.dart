import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RawMaterialsRepository {
  final SupabaseClient _supabase;

  RawMaterialsRepository(this._supabase);

  // --- Raw Materials ---

  // Real-time stream for raw materials
  // Joining with measures to get the measure name if needed (though UI might just show ID or look it up)
  // For now let's just get the raw table data.
  Future<List<Map<String, dynamic>>> getRawMaterials() async {
    final data = await _supabase
        .from('raw_materials')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> createRawMaterial({
    required String name,
    required String measureId,
    required double coverage,
    required double cost,
    required double price,
  }) async {
    final res = await _supabase.from('raw_materials').insert({
      'name': name,
      'measure_id': measureId,
      'coverage': coverage,
      'cost': cost,
      'price': price,
    }).select().single();
    return res['id'] as String;
  }

  Future<void> updateRawMaterial({
    required String id,
    required String name,
    required String measureId,
    required double coverage,
    required double cost,
    required double price,
  }) async {
    await _supabase.from('raw_materials').update({
      'name': name,
      'measure_id': measureId,
      'coverage': coverage,
      'cost': cost,
      'price': price,
    }).eq('id', id);
  }

  Future<void> deleteRawMaterial(String id) async {
    await _supabase.from('raw_materials').delete().eq('id', id);
  }
}

final rawMaterialsRepositoryProvider = Provider<RawMaterialsRepository>((ref) {
  return RawMaterialsRepository(Supabase.instance.client);
});

final rawMaterialsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(rawMaterialsRepositoryProvider).getRawMaterials();
});
