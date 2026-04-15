import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/project_repository.dart';
import '../models/project_models.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../accounts_payable/providers/accounts_payable_provider.dart';
import '../../accounts_payable/models/account_payable_model.dart';

// Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(Supabase.instance.client);
});

// --- Streams ---

// 1. Projects List
final projectListProvider =
    StreamProvider.autoDispose<List<ProjectModel>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectsStream();
});

// 1.5 Clients List
final clientListProvider =
    FutureProvider.autoDispose<List<ClientSimpleModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('clients')
      .select('id, first_name, last_name, photo_url, phone, address')
      .order('first_name', ascending: true);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((e) => ClientSimpleModel.fromJson(e)).toList();
});

// 1.7 Profiles List
final profilesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('profiles')
      .select('id, full_name, picture')
      .order('full_name', ascending: true);
  return List<Map<String, dynamic>>.from(response as List);
});

// 2. Project Costs (Family)
final projectCostsProvider = StreamProvider.autoDispose
    .family<List<ProjectCostModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getCostsStream(projectId);
});

// 3. Project Media (Family)
final projectMediaProvider = StreamProvider.autoDispose
    .family<List<ProjectMediaModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getMediaStream(projectId);
});

// 4. Project Chat (Family)
final projectChatProvider = StreamProvider.autoDispose
    .family<List<ProjectChatModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getChatStream(projectId);
});

// 5. Single Project (Family)
final projectDetailProvider =
    Provider.autoDispose.family<ProjectModel?, String>((ref, projectId) {
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
final projectPoleBarnsProvider = FutureProvider.autoDispose
    .family<List<ProjectPoleBarnModel>, String>((ref, projectId) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectPoleBarns(projectId);
});

final projectPoleBarnsStreamProvider = StreamProvider.autoDispose
    .family<List<ProjectPoleBarnModel>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectPoleBarnsStream(projectId);
});

// 7. Pole Barns Catalog
final poleBarnsCatalogProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getPoleBarnsCatalog();
});

// 8. Project Pole Barns Materials (For new Products tab)
final projectPoleBarnsMaterialsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectRoleBarnMaterials(projectId);
});

// --- Master Detail State ---

final projectInvoiceBalanceProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, projectId) {
  final project = ref.watch(projectDetailProvider(projectId));
  final apTotalAsync =
      ref.watch(projectAccountsPayableTotalProvider(projectId));

  return apTotalAsync.whenData((apTotal) {
    if (project == null) return 0.0;
    return project.ventaTotal - apTotal;
  });
});

final projectIncomesProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, projectId) {
  final invoicesAsync = ref.watch(invoicesStreamProvider);
  return invoicesAsync.whenData((invoices) {
    try {
      final invoice = invoices.firstWhere((inv) => inv.idProyecto == projectId);
      return invoice.totalPagado;
    } catch (_) {
      return 0.0;
    }
  });
});

final projectClientBalanceProvider =
    Provider.family<AsyncValue<double>, String>((ref, projectId) {
  final project = ref.watch(projectDetailProvider(projectId));
  final incomesAsync = ref.watch(projectIncomesProvider(projectId));

  return incomesAsync.whenData((incomes) {
    if (project == null) return 0.0;
    return project.ventaTotal - incomes;
  });
});

final projectAccountsPayableTotalProvider =
    Provider.family<AsyncValue<double>, String>((ref, projectId) {
  final accountsAsync = ref.watch(accountsPayableListProvider);
  return accountsAsync.whenData((accounts) => accounts
      .where((a) => a.projectId == projectId)
      .fold(0.0, (sum, a) => sum + a.totalAmount));
});

final projectAccountsPayableListProvider =
    Provider.family<AsyncValue<List<AccountPayableModel>>, String>(
        (ref, projectId) {
  final accountsAsync = ref.watch(accountsPayableListProvider);
  return accountsAsync.whenData(
      (accounts) => accounts.where((a) => a.projectId == projectId).toList());
});

// --- Master Detail State ---
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

final projectInvoiceDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, projectId) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectInvoiceDetails(projectId);
});

class ProjectDraft {
  final String projectName;
  final String address;
  final String? clientId;
  final String? responsible;
  final List<String> groupUsers;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String comments;
  final List<Map<String, dynamic>> structures;

  ProjectDraft({
    this.projectName = '',
    this.address = '',
    this.clientId,
    this.responsible,
    this.groupUsers = const [],
    this.status = 'En Proceso',
    DateTime? startDate,
    DateTime? endDate,
    this.comments = '',
    this.structures = const [],
  }) : startDate = startDate ?? DateTime.now(),
       endDate = endDate ?? DateTime.now().add(const Duration(days: 30));

  ProjectDraft copyWith({
    String? projectName,
    String? address,
    bool nullClientId = false,
    String? clientId,
    bool nullResponsible = false,
    String? responsible,
    List<String>? groupUsers,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? comments,
    List<Map<String, dynamic>>? structures,
  }) {
    return ProjectDraft(
      projectName: projectName ?? this.projectName,
      address: address ?? this.address,
      clientId: nullClientId ? null : (clientId ?? this.clientId),
      responsible: nullResponsible ? null : (responsible ?? this.responsible),
      groupUsers: groupUsers ?? this.groupUsers,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      comments: comments ?? this.comments,
      structures: structures ?? this.structures,
    );
  }
}

class ProjectDraftNotifier extends StateNotifier<ProjectDraft> {
  ProjectDraftNotifier() : super(ProjectDraft());

  void updateDraft(ProjectDraft newDraft) {
    state = newDraft;
  }

  void clearDraft() {
    state = ProjectDraft();
  }
}

final projectDraftProvider = StateNotifierProvider<ProjectDraftNotifier, ProjectDraft>((ref) {
  return ProjectDraftNotifier();
});
