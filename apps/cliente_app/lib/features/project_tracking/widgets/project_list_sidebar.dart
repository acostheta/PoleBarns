import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../models/project_models.dart';
import 'project_create_dialog.dart';

class ProjectListSidebar extends ConsumerStatefulWidget {
  const ProjectListSidebar({super.key});

  @override
  ConsumerState<ProjectListSidebar> createState() => _ProjectListSidebarState();
}

class _ProjectListSidebarState extends ConsumerState<ProjectListSidebar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final selectedId = ref.watch(selectedProjectIdProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Proyectos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827), // Gray-900
                      ),
                    ),
                    projectsAsync.when(
                      data: (list) => Text(
                        '${list.length} Activos',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Nuevo Proyecto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Stack(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    fillColor: const Color(0xFFF5F5F4), // Stone-100
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                final clients = ref.watch(clientListProvider).valueOrNull;

                final filtered = projects.where((p) {
                  final query = _searchQuery.toLowerCase();
                  final client = clients?.firstWhere(
                      (c) => c.id == p.refCliente,
                      orElse: () => ClientSimpleModel(
                          id: '', firstName: '', lastName: ''));

                  return (p.address?.toLowerCase().contains(query) ?? false) ||
                      (p.direccion?.toLowerCase().contains(query) ?? false) ||
                      (client?.fullName.toLowerCase().contains(query) ??
                          false) ||
                      (client?.phone?.toLowerCase().contains(query) ?? false) ||
                      (p.id.toLowerCase().contains(query));
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No projects found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final project = filtered[index];
                    final isSelected = project.id == selectedId;

                    return _ProjectListItem(
                      project: project,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedProjectIdProvider.notifier).state =
                            project.id;
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => const ProjectCreateDialog(),
    );
  }
}

class _ProjectListItem extends StatelessWidget {
  final ProjectModel project;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectListItem({
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors based on selection from Tailwind design (Polebarn CRM)
    // Select: bg-amber-50 (or similar light yellow) border-l-4 border-amber-500

    final backgroundColor =
        isSelected ? const Color(0xFFFFFBEB) : Colors.transparent; // Amber-50
    final borderColor =
        isSelected ? const Color(0xFFF59E0B) : Colors.transparent; // Amber-500
    final titleColor = isSelected
        ? const Color(0xFF92400E)
        : const Color(0xFF1F2937); // Amber-800 vs Gray-800
    final subtitleColor = isSelected
        ? const Color(0xFFB45309)
        : const Color(0xFF6B7280); // Amber-700 vs Gray-500

    return Consumer(builder: (context, ref, child) {
      final clientsAsync = ref.watch(clientListProvider);
      final client = clientsAsync.valueOrNull?.firstWhere(
        (c) => c.id == project.refCliente,
        orElse: () =>
            ClientSimpleModel(id: '', firstName: 'Unknown', lastName: ''),
      );

      final displayAddress =
          (project.direccion != null && project.direccion!.isNotEmpty)
              ? project.direccion!
              : (client?.address ?? (project.address ?? 'Sin Dirección'));

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFF5F5F4), // Stone-100
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: borderColor,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.address ?? 'Proyecto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontSize: 15,
                ),
              ),
              if (displayAddress != (project.address ?? ''))
                Text(
                  displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      client?.fullName ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '#PROJ-${project.id.substring(0, 4).toUpperCase()}',
                    style: TextStyle(
                      color: subtitleColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (client?.phone != null) ...[
                const SizedBox(height: 2),
                Text(
                  client!.phone!,
                  style: TextStyle(
                    color: subtitleColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
