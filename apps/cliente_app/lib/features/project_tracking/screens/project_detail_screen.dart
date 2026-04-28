import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../providers/project_providers.dart';
import '../widgets/products_tab.dart';
import '../widgets/evidence_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/project_create_dialog.dart';
import '../../../shared/widgets/location_map_card.dart';

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
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.address ?? 'Detalle de Obra',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                  fontSize: 18,
                ),
              ),
              Text(
                '#PROJ-${project.id.substring(0, 8)}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              )
            ],
          ),
          backgroundColor: AppStyles.primaryForest,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ProjectCreateDialog(
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
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
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
                tabs: [
                  Tab(text: 'PRODUCTOS'),
                  Tab(text: 'EVIDENCIAS'),
                  Tab(text: 'CHAT'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: AppStyles.stoneWhite,
        title: const Text(
          'Confirmar Eliminación',
          style: TextStyle(
            color: AppStyles.primaryForest,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        content: const Text(
          '¿Estás seguro de eliminar este proyecto? Esta acción no se puede deshacer.',
          style: TextStyle(fontFamily: 'Manrope'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
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
