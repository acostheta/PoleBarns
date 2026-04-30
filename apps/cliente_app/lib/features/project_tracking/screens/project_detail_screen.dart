import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../providers/project_providers.dart';
import '../widgets/products_tab.dart';
import '../widgets/evidence_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/project_create_dialog.dart';
import '../../../shared/widgets/location_map_card.dart';
import '../../../shared/widgets/app_bar_portal.dart';
import '../../../config/ui_helpers.dart';

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
        backgroundColor: AppStyles.stoneWhite,
        body: Column(
          children: [
            AppBarPortal(
              title: project.address ?? 'Detalle de Obra',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                  onPressed: () {
                    AppBottomSheet.show(
                      context: context,
                      child: ProjectCreateDialog(
                        projectId: project.id,
                        initialClientId: project.refCliente,
                        initialProjectName: project.address,
                        initialDireccion: project.direccion,
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
                  },
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => _confirmDelete(context, ref, project.id),
                  tooltip: 'Eliminar',
                ),
                const SizedBox(width: 8),
              ],
            ),
            Container(
              color: AppStyles.paleSage,
              child: const TabBar(
                isScrollable: true,
                labelColor: AppStyles.primaryForest,
                unselectedLabelColor: Color(0xFF6B7280),
                indicatorColor: AppStyles.secondaryEarth,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'PRODUCTOS'),
                  Tab(text: 'EVIDENCIA'),
                  Tab(text: 'CHAT'),
                ],
              ),
            ),
            // Top Accent Bar
            Container(
              height: 4,
              color: AppStyles.secondaryEarth,
            ),
            if ((project.direccion ?? project.address ?? '').isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: LocationMapCard(
                    address: project.direccion ?? project.address ?? ''),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  ProductsTab(projectId: project.id),
                  EvidenceTab(projectId: project.id),
                  ChatTab(projectId: project.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String projectId) async {
    final confirmed = await AppBottomSheet.showConfirm(
      context: context,
      title: 'Confirmar Eliminación',
      message: '¿Estás seguro de eliminar este proyecto? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
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
