import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pole_barn_model.dart';
import '../models/related_material_model.dart';

class PoleBarnRepository {
  final SupabaseClient _supabase;

  PoleBarnRepository(this._supabase);

  // Get all PoleBarns stream
  Stream<List<PoleBarn>> watchPoleBarns() {
    return _supabase
        .from('PoleBarns')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => PoleBarn.fromJson(json)).toList());
  }

  // Get single PoleBarn stream for realtime totals
  Stream<PoleBarn?> watchPoleBarn(int id) {
    return _supabase
        .from('PoleBarns')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? PoleBarn.fromJson(data.first) : null);
  }

  Future<PoleBarn> getPoleBarn(int id) async {
    final response =
        await _supabase.from('PoleBarns').select().eq('id', id).single();
    return PoleBarn.fromJson(response);
  }

  Future<List<RelatedMaterial>> getRelatedMaterials(int poleBarnId) async {
    final response = await _supabase
        .from('RelatedMaterials')
        .select('*, raw_materials(name)')
        .eq('PoleBarns_Ref', poleBarnId);

    return (response as List).map((e) => RelatedMaterial.fromJson(e)).toList();
  }

  Future<int> upsertPoleBarn(PoleBarn poleBarn) async {
    final response = await _supabase
        .from('PoleBarns')
        .upsert(poleBarn.toJson())
        .select()
        .single();
    return response['id'];
  }

  Future<void> saveRelatedMaterials(
      int poleBarnId, List<RelatedMaterial> materials) async {
    // 1. Delete materials that are no longer in the current list
    final currentIds =
        materials.where((m) => m.id != null).map((m) => m.id!).toList();

    if (currentIds.isNotEmpty) {
      await _supabase
          .from('RelatedMaterials')
          .delete()
          .eq('PoleBarns_Ref', poleBarnId)
          .not('id', 'in', currentIds);
    } else {
      await _supabase
          .from('RelatedMaterials')
          .delete()
          .eq('PoleBarns_Ref', poleBarnId);
    }

    // 2. Separate inserts from updates to avoid batch schema issues
    final toInsert = materials.where((m) => m.id == null).map((m) {
      final json = m.toJson();
      json['PoleBarns_Ref'] = poleBarnId;
      return json;
    }).toList();

    final toUpdate = materials.where((m) => m.id != null).map((m) {
      final json = m.toJson();
      json['PoleBarns_Ref'] = poleBarnId;
      return json;
    }).toList();

    // 3. Perform operations
    if (toInsert.isNotEmpty) {
      await _supabase.from('RelatedMaterials').insert(toInsert);
    }

    if (toUpdate.isNotEmpty) {
      await _supabase.from('RelatedMaterials').upsert(toUpdate);
    }
  }

  Future<void> deleteRelatedMaterial(int id) async {
    await _supabase.from('RelatedMaterials').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getRawMaterials() async {
    final response = await _supabase
        .from('raw_materials')
        .select('id, name, price, measures(name)')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deletePoleBarn(int id) async {
    await _supabase.from('PoleBarns').delete().eq('id', id);
  }
}
