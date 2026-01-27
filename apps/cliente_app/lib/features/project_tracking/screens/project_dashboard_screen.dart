import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../widgets/project_list_sidebar.dart';
import '../widgets/project_detail_view.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Custom Colors from design
    const bgLight = Color(0xFFFDFBF7); // Stone-50 like
    // const bgDark = Color(0xFF2C2A26); // Dark mode not strictly required yet but good to know

    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Left Sidebar (Project List)
          const SizedBox(
            width: 320,
            child: ProjectListSidebar(),
          ),

          // Vertical Divider
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),

          // Right Content (Project Details)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedId = ref.watch(selectedProjectIdProvider);
                if (selectedId == null) {
                  return const Center(
                    child: Text(
                      'Selecciona un proyecto para ver los detalles',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                return ProjectDetailView(projectId: selectedId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
