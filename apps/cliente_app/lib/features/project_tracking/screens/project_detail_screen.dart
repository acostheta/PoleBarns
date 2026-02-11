import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../providers/project_providers.dart';
import '../widgets/products_tab.dart';
import '../widgets/evidence_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/project_create_dialog.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId));

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.address ?? 'Detalle de Obra',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              Text(
                '#PROJ-${project.id.substring(0, 8)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            // Add Edit/Delete Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (ctx) => ProjectCreateDialog(
                      projectId: project.id,
                      initialClientId: project.refCliente,
                      initialProjectName: project.address,
                      initialResponsible: project.responsable,
                      initialGroupId: project.grupoAsignado != null &&
                              project.grupoAsignado!.isNotEmpty
                          ? project.grupoAsignado
                          : null,
                      initialStatus: project.estatus,
                      initialStartDate: project.fechaInicio,
                      initialEndDate: project.fechaFinalizacion,
                      initialComments: project.comments,
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, ref, project.id);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppStyles.primaryOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppStyles.primaryOrange,
            tabs: [
              Tab(text: 'Productos'),
              Tab(text: 'Evidencias'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProductsTab(projectId: project.id),
            EvidenceTab(projectId: project.id),
            ChatTab(projectId: project.id),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
            '¿Estás seguro de eliminar este proyecto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(projectId);
        if (context.mounted) {
          Navigator.of(context).pop(); // Return to list
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proyecto eliminado')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
