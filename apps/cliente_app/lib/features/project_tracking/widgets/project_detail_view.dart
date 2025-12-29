import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import 'sections/project_form_section.dart';
import 'sections/project_financial_section.dart';
import 'sections/project_gallery_section.dart';
import 'sections/project_chat_section.dart';
import 'sections/project_pole_barns_section.dart';
import 'project_create_dialog.dart';
import '../models/project_models.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../invoices/screens/invoice_detail_screen.dart';

class ProjectDetailView extends ConsumerWidget {
  final String projectId;

  const ProjectDetailView({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId));
    // Provide a way to refresh or ensure we have recent data.
    // The provider is a stream derived provider so it updates automatically.

    if (project == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Colors
    const primaryColor = Color(0xFFD97706); // Amber-600
    const accentGreen = Color(0xFF166534); // Green-800

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Background Light
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                const Text(
                  'Project Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Gray-900
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final invoice = await ref
                              .read(invoiceByProjectProvider(projectId).future);

                          if (invoice != null) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoiceDetailScreen(
                                      invoiceId: invoice.id),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No hay una factura vinculada a este proyecto.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error al buscar factura: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: const Text('Ver Factura'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, ref, projectId),
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        elevation: 0,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context, ref),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add New Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Content Grid/Stack
            // We use a Column for vertical stacking as requested, matching the "Right Panel" design.
            // "Section 2: Details" & "Section 3: Costs" etc.

            // 1. Details Form
            ProjectFormSection(project: project),
            const SizedBox(height: 32),

            // 1.5 Pole Barns (Structures)
            ProjectPoleBarnsSection(projectId: project.id),
            const SizedBox(height: 32),

            // 2. Costs
            ProjectFinancialSection(project: project),
            const SizedBox(height: 32),

            // 3. Photos
            ProjectGallerySection(projectId: project.id),
            const SizedBox(height: 32),

            // 4. Chat
            SizedBox(
              height:
                  600, // Fixed height container for Chat as per HTML design "h-[500px]"
              child: ProjectChatSection(projectId: project.id),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Proyecto?'),
        content: const Text(
            'Esta acción no se puede deshacer. Toda la información del proyecto se perderá para siempre.'),
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

    if (confirm == true) {
      await ref.read(projectRepositoryProvider).deleteProject(projectId);
      ref.read(selectedProjectIdProvider.notifier).state =
          null; // Clear selection
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => const ProjectCreateDialog(),
    );
  }
}
