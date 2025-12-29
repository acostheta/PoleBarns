import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_models.dart';

class ProjectRepository {
  final SupabaseClient _supabase;

  ProjectRepository(this._supabase);

  // --- Projects ---

  Stream<List<ProjectModel>> getProjectsStream() {
    return _supabase
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
            (data) => data.map((json) => ProjectModel.fromJson(json)).toList());
  }

  Future<void> createProject(ProjectModel project) async {
    await _supabase.from('projects').insert(project.toJson());
  }

  Future<void> updateProject(ProjectModel project) async {
    await _supabase
        .from('projects')
        .update(project.toJson())
        .eq('id', project.id);
  }

  Future<void> deleteProject(String projectId) async {
    await _supabase.from('projects').delete().eq('id', projectId);
  }

  // --- Costs ---

  Stream<List<ProjectCostModel>> getCostsStream(String projectId) {
    return _supabase
        .from('project_costs')
        .stream(primaryKey: ['id'])
        .eq('project_ref', projectId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => ProjectCostModel.fromJson(json)).toList());
  }

  Future<void> addCost(
      String projectId, String concepto, double monto, String? notas) async {
    await _supabase.from('project_costs').insert({
      'project_ref': projectId,
      'concepto': concepto,
      'monto': monto,
      'notas': notas,
    });
  }

  // --- Media ---

  Stream<List<ProjectMediaModel>> getMediaStream(String projectId) {
    return _supabase
        .from('project_media')
        .stream(primaryKey: ['id'])
        .eq('project_ref', projectId)
        .order('order_index', ascending: true)
        .map((data) =>
            data.map((json) => ProjectMediaModel.fromJson(json)).toList());
  }

  Future<void> addMedia({
    required String projectId,
    required String url,
    required String tipo,
    required String etiqueta,
    int orderIndex = 0,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('project_media').insert({
      'project_ref': projectId,
      'url_media': url,
      'tipo': tipo,
      'etiqueta': etiqueta,
      'usuario_carga_ref': userId,
      'order_index': orderIndex,
    });
  }

  Future<void> deleteMedia(String mediaId) async {
    await _supabase.from('project_media').delete().eq('id', mediaId);
  }

  Future<void> updateMediaOrder(List<ProjectMediaModel> sortedMedia) async {
    final updates = sortedMedia.asMap().entries.map((entry) {
      return {
        'id': entry.value.id,
        'order_index': entry.key,
      };
    }).toList();

    // Use upsert to update multiple rows.
    // Note: Upsert needs the full object or it might clear other fields if not handled by DB.
    // In Supabase/PostgREST, upsert with partial data works if primary key is provided and 'onConflict' is used.
    await _supabase.from('project_media').upsert(updates, onConflict: 'id');
  }

  // --- Chat ---

  Stream<List<ProjectChatModel>> getChatStream(String projectId) {
    return _supabase
        .from('project_chat')
        .stream(primaryKey: ['id'])
        .eq('project_ref', projectId)
        .order('created_at',
            ascending:
                true) // Oldest first for chat bubbles usually, but UI might reverse
        .map((data) =>
            data.map((json) => ProjectChatModel.fromJson(json)).toList());
  }

  Future<void> sendMessage(String projectId, String message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // In a real app, user metadata might be fetched from a 'profiles' table or auth metadata
    final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Usuario';
    final userPhoto = user.userMetadata?['avatar_url'];

    await _supabase.from('project_chat').insert({
      'project_ref': projectId,
      'usuario_ref': user.id,
      'nombre_desnormalizado': userName,
      'photo_desnormalizado': userPhoto,
      'mensaje': message,
    });
  }

  // --- Pole Barns Integration ---

  Future<List<ProjectPoleBarnModel>> getProjectPoleBarns(
      String projectId) async {
    final response = await _supabase
        .from('project_pole_barns')
        .select('*, PoleBarns(name)')
        .eq('project_id', projectId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => ProjectPoleBarnModel.fromJson(json))
        .toList();
  }

  Future<void> addProjectPoleBarn(
      String projectId, int poleBarnId, double salePrice) async {
    await _supabase.from('project_pole_barns').insert({
      'project_id': projectId,
      'pole_barn_id': poleBarnId,
      'sale_price': salePrice,
    });
  }

  Future<void> updateProjectPoleBarnPrice(String id, double newPrice) async {
    await _supabase
        .from('project_pole_barns')
        .update({'sale_price': newPrice}).eq('id', id);
  }

  Future<void> deleteProjectPoleBarn(String id) async {
    await _supabase.from('project_pole_barns').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getPoleBarnsCatalog() async {
    final response = await _supabase
        .from('PoleBarns')
        .select('id, name, precio_venta')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}
