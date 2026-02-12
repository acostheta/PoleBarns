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

  Future<ProjectModel> createProject(ProjectModel project) async {
    final response = await _supabase
        .from('projects')
        .insert(project.toJson())
        .select()
        .single();
    return ProjectModel.fromJson(response);
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

  Future<ProjectMediaModel> addMedia({
    required String projectId,
    required String url,
    required DateTime fecha,
    String? descripcion,
    int orderIndex = 0,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // Get user name from profiles
    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    final userName = profile?['full_name'] ?? 'Usuario';

    final response = await _supabase
        .from('project_media')
        .insert({
          'project_ref': projectId,
          'url_media': url,
          'fecha': fecha.toIso8601String().split('T')[0],
          'descripcion': descripcion,
          'usuario_carga_ref': userId,
          'usuario_nombre': userName,
          'order_index': orderIndex,
        })
        .select()
        .single();

    return ProjectMediaModel.fromJson(response);
  }

  Future<void> updateMediaMetadata({
    required String mediaId,
    required DateTime fecha,
    String? descripcion,
  }) async {
    await _supabase.from('project_media').update({
      'fecha': fecha.toIso8601String().split('T')[0],
      'descripcion': descripcion,
    }).eq('id', mediaId);
  }

  Future<void> deleteMedia(String mediaId) async {
    await _supabase.from('project_media').delete().eq('id', mediaId);
  }

  Future<void> updateMediaDescription(
      String mediaId, String description) async {
    await _supabase
        .from('project_media')
        .update({'descripcion': description}).eq('id', mediaId);
  }

  Future<void> deleteMediaBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    await _supabase.from('project_media').delete().inFilter('id', ids);
  }

  Future<void> updateMediaOrder(List<ProjectMediaModel> sortedMedia) async {
    final updates = sortedMedia.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key).toJson();
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

    // Fetch user profile to get desnormalizado name and photo
    final profile = await _supabase
        .from('profiles')
        .select('full_name, picture')
        .eq('id', user.id)
        .maybeSingle();

    final userName =
        profile?['full_name'] ?? user.userMetadata?['full_name'] ?? 'Usuario';
    final userPhoto = profile?['picture'] ?? user.userMetadata?['avatar_url'];

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

  Stream<List<ProjectPoleBarnModel>> getProjectPoleBarnsStream(
      String projectId) {
    return _supabase
        .from('project_pole_barns')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: true)
        .map((data) =>
            data.map((json) => ProjectPoleBarnModel.fromJson(json)).toList());
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

  Future<void> updateProjectPoleBarnStatus(
      String productId, String status, String projectId) async {
    // 1. Update product status
    await _supabase
        .from('project_pole_barns')
        .update({'status': status}).eq('id', productId);

    // 2. Fetch all products for this project to calculate overall status
    final products = await getProjectPoleBarns(projectId);

    String overallStatus;
    if (products.isEmpty) {
      overallStatus = 'Pendiente';
    } else if (products.every((p) => p.status == 'Terminado')) {
      overallStatus = 'Terminado';
    } else if (products.every((p) => p.status == 'Pendiente')) {
      overallStatus = 'Pendiente';
    } else {
      overallStatus = 'En Proceso';
    }

    // 3. Update project status
    await _supabase
        .from('projects')
        .update({'estatus': overallStatus}).eq('id', projectId);
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

  Future<List<Map<String, dynamic>>> getProjectRoleBarnMaterials(
      String projectId) async {
    // 1. Get Project Pole Barns to know which Barns are in the project
    final projectBarns = await getProjectPoleBarns(projectId);

    // 2. For each barn, fetch its related materials
    List<Map<String, dynamic>> result = [];

    for (var pBarn in projectBarns) {
      final response = await _supabase
          .from('RelatedMaterials')
          .select('*, raw_materials(name)')
          .eq('PoleBarns_Ref', pBarn.poleBarnId);

      final materials = List<Map<String, dynamic>>.from(response);

      result.add({'project_pole_barn': pBarn, 'materials': materials});
    }

    return result;
  }

  // --- Financial Summaries ---

  Future<Map<String, dynamic>?> getProjectInvoiceDetails(
      String projectId) async {
    final response = await _supabase
        .from('Invoices')
        .select('id, Address')
        .eq('IdProyecto', projectId)
        .maybeSingle();

    return response;
  }

  Future<double> getProjectInvoiceBalance(String projectId) async {
    final response = await _supabase
        .from('Invoices')
        .select('Saldo')
        .eq('IdProyecto', projectId)
        .maybeSingle();

    if (response == null) return 0.0;
    return (response['Saldo'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getProjectTotalAccountsPayable(String projectId) async {
    final response = await _supabase
        .from('accounts_payable')
        .select('total_amount')
        .eq('project_id', projectId);

    final List<dynamic> data = response as List<dynamic>;
    double total = 0.0;
    for (var item in data) {
      total += (item['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }
}
