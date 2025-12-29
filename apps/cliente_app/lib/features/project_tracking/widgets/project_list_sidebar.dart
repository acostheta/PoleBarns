import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../models/project_models.dart';

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Gray-900
                  ),
                ),
                projectsAsync.when(
                  data: (list) => Text(
                    '${list.length} Active',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
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
                final filtered = projects.where((p) {
                  final query = _searchQuery.toLowerCase();
                  return (p.address?.toLowerCase().contains(query) ?? false) ||
                      (p.refCliente.toLowerCase().contains(query));
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
              project.address ?? 'Untitled Project',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: titleColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#PROJ-${project.id.substring(0, 4).toUpperCase()}',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
