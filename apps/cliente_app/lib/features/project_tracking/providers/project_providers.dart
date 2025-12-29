import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/project_repository.dart';
import '../models/project_models.dart';

// Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(Supabase.instance.client);
});

// --- Streams ---

// 1. Projects List
final projectListProvider = StreamProvider<List<ProjectModel>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectsStream();
});

// 1.5 Clients List
final clientListProvider = FutureProvider<List<ClientSimpleModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('clients')
      .select('id, first_name, last_name')
      .order('first_name', ascending: true);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((e) => ClientSimpleModel.fromJson(e)).toList();
});

// 2. Project Costs (Family)
final projectCostsProvider =
    StreamProvider.family<List<ProjectCostModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getCostsStream(projectId);
});

// 3. Project Media (Family)
final projectMediaProvider =
    StreamProvider.family<List<ProjectMediaModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getMediaStream(projectId);
});

// 4. Project Chat (Family)
final projectChatProvider =
    StreamProvider.family<List<ProjectChatModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getChatStream(projectId);
});

// 5. Single Project (Family) - Derived from List for simplicity or separate fetch
// For realtime updates on the detail screen, it's best to either:
// a) Stream the single document (Repository needs a method)
// b) Watch the list and find the item.
// Let's us (b) for now as it's efficient if list is small, or add (a) later.
// Actually, let's add a single project stream to repository if needed, but for now:
final projectDetailProvider =
    Provider.family<ProjectModel?, String>((ref, projectId) {
  final projectsAsync = ref.watch(projectListProvider);
  return projectsAsync.when(
    data: (projects) => projects.cast<ProjectModel?>().firstWhere(
          (p) => p!.id == projectId,
          orElse: () => null,
        ),
    loading: () => null,
    error: (_, __) => null,
  );
});

// 6. Project Pole Barns (Associations)
final projectPoleBarnsProvider =
    FutureProvider.family<List<ProjectPoleBarnModel>, String>(
        (ref, projectId) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectPoleBarns(projectId);
});

// 7. Pole Barns Catalog
final poleBarnsCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getPoleBarnsCatalog();
});

// --- Master Detail State ---
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);
