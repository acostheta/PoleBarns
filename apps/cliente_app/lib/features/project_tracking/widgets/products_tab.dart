import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';

import '../../clients/repositories/client_repository.dart';
import '../utils/project_materials_pdf_generator.dart';

class ProductsTab extends ConsumerWidget {
  final String projectId;

  const ProductsTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId));
    final productsAsync =
        ref.watch(projectPoleBarnsMaterialsProvider(projectId));
    final invoiceDetailsAsync =
        ref.watch(projectInvoiceDetailsProvider(projectId));

    if (project == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detalles del Proyecto',
                  style: AppStyles.dialogTitleStyle),
              ElevatedButton.icon(
                onPressed: () async {
                  // Fetch Client
                  final clientRepo = ref.read(clientRepositoryProvider);
                  // Assuming refCliente is the ID.
                  final client = await clientRepo.getClient(project.refCliente);

                  // Get products data
                  final items = productsAsync.value ?? [];

                  if (context.mounted) {
                    await ProjectMaterialsPdfGenerator.generate(
                      project: project,
                      client: client,
                      items: items,
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar Lista'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHeader(project, invoiceDetailsAsync.asData?.value),
          const SizedBox(height: 24),
          const Text('Estructuras del Proyecto',
              style: AppStyles.dialogTitleStyle),
          const SizedBox(height: 16),
          productsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No hay productos asignados.'));
              }
              // ... existing list generation ...
              return Column(
                children: items.map((item) {
                  final ProjectPoleBarnModel poleBarn =
                      item['project_pole_barn'];
                  final List<dynamic> materials = item['materials'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Product Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryOrange
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.home_work_outlined,
                                    color: AppStyles.primaryOrange),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    poleBarn.poleBarnName ?? 'Estructura',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  Text(
                                    'Precio Venta: ${NumberFormat.simpleCurrency().format(poleBarn.salePrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Materials Table
                          const Text(
                            'Materiales',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (materials.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No hay materiales detallados.',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic)),
                            )
                          else
                            _buildMaterialsTable(materials),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      ProjectModel project, Map<String, dynamic>? invoiceDetails) {
    // Determine Address: prioritize Invoice Address, fallback to project address (might be name)
    final address =
        invoiceDetails?['Address'] ?? project.address ?? 'No disponible';
    final invoiceId = invoiceDetails?['id']?.toString() ?? 'N/A';

    final startDate = project.fechaInicio != null
        ? DateFormat('MM/dd/yyyy').format(project.fechaInicio!)
        : 'N/A';
    final endDate = project.fechaFinalizacion != null
        ? DateFormat('MM/dd/yyyy').format(project.fechaFinalizacion!)
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROYECTO',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(project.address ?? "Sin Nombre",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              // Invoice ID removed as requested
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // Row 1: 3 Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildInfoRow(
                      Icons.location_on_outlined, 'Dirección', address)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildInfoRow(Icons.group_outlined, 'Grupo',
                      project.grupoAsignado ?? 'N/A')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildInfoRow(Icons.manage_accounts_outlined,
                      'Responsable', project.responsable ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 24),
          // Row 2: 3 Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildInfoRow(Icons.calendar_today_outlined,
                      'Fecha Inicio', startDate)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildInfoRow(
                      Icons.event_available_outlined, 'Fecha Fin', endDate)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildInfoRow(
                      Icons.info_outline, 'Estatus', project.estatus ?? "N/A")),
            ],
          ),
          const SizedBox(height: 24),
          // Row 3: Comments (Full Width)
          _buildInfoRow(
              Icons.comment_outlined, 'Comentarios', project.comments ?? 'N/A',
              maxLines: 5),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTable(List<dynamic> materials) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE5E7EB), width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2), // Material Name
        1: FlexColumnWidth(1), // Quantity
        2: FlexColumnWidth(1), // Unit
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            _buildTableHeader('Material'),
            _buildTableHeader('Cantidad'),
            _buildTableHeader('Medida'),
          ],
        ),
        // Rows
        ...materials.map((m) {
          final name = m['raw_materials']?['name'] ??
              m['RawMaterials']?['name'] ??
              'Desconocido';

          final qty = m['Qty'] ?? m['qty'] ?? 0;
          final unit = m['Medida'] ?? m['medida'] ?? '-';

          return TableRow(
            children: [
              _buildTableCell(name),
              _buildTableCell(qty.toString()),
              _buildTableCell(unit.toString()),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
      ),
    );
  }
}
