import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import 'sections/project_form_section.dart';
import 'sections/project_financial_section.dart';
import 'sections/project_gallery_section.dart';
import 'sections/project_chat_section.dart';
import 'sections/project_pole_barns_section.dart';

import '../../invoices/providers/invoice_providers.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../../providers/navigation_providers.dart';
import '../../../config/ui_helpers.dart';

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
                    Consumer(builder: (context, ref, child) {
                      final invoiceAsync =
                          ref.watch(invoiceByProjectProvider(projectId));

                      return invoiceAsync.when(
                        data: (invoice) {
                          final hasInvoice = invoice != null;
                          return ElevatedButton.icon(
                            onPressed: () {
                              if (hasInvoice) {
                                // Switch to Invoices module and select this invoice
                                ref
                                    .read(dashboardIndexProvider.notifier)
                                    .state = DashboardIndices.invoices;
                                ref
                                    .read(selectedInvoiceIdProvider.notifier)
                                    .state = invoice.id;
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateInvoiceScreen(
                                        projectId: projectId),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                                hasInvoice
                                    ? Icons.receipt_long
                                    : Icons.post_add,
                                size: 20),
                            label: Text(
                                hasInvoice ? 'Ver Factura' : 'Crear Factura'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        loading: () => const ElevatedButton(
                          onPressed: null,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        error: (e, st) => IconButton(
                          onPressed: () => ref
                              .invalidate(invoiceByProjectProvider(projectId)),
                          icon: const Icon(Icons.refresh, color: Colors.red),
                        ),
                      );
                    }),
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

            // 2. Costs
            ProjectFinancialSection(project: project),
            const SizedBox(height: 32),

            // 1.5 Pole Barns (Structures)
            ProjectPoleBarnsSection(projectId: project.id),
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
    final confirm = await AppBottomSheet.showConfirm(
      context: context,
      title: '¿Eliminar Proyecto?',
      message: 'Esta acción no se puede deshacer. Toda la información del proyecto se perderá para siempre.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (confirm == true) {
      await ref.read(projectRepositoryProvider).deleteProject(projectId);
      ref.read(selectedProjectIdProvider.notifier).state =
          null; // Clear selection
    }
  }
}
