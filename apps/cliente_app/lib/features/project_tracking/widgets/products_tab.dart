import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

    final clientsAsync = ref.watch(clientListProvider);
    final client = clientsAsync.valueOrNull?.firstWhere(
      (c) => c.id == project.refCliente,
      orElse: () =>
          ClientSimpleModel(id: '', firstName: 'Unknown', lastName: ''),
    );

    final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        'Detalles de ${((project.direccion != null && project.direccion!.isNotEmpty) ? project.direccion! : (client?.address ?? (project.address ?? "Proyecto")))}',
                        style: AppStyles.dialogTitleStyle),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final clientRepo = ref.read(clientRepositoryProvider);
                        final clientData =
                            await clientRepo.getClient(project.refCliente);
                        final items = productsAsync.value ?? [];
                        if (context.mounted) {
                          await ProjectMaterialsPdfGenerator.generate(
                            project: project,
                            client: clientData,
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
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Detalles de ${((project.direccion != null && project.direccion!.isNotEmpty) ? project.direccion! : (client?.address ?? (project.address ?? "Proyecto")))}',
                        style: AppStyles.dialogTitleStyle),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final clientRepo = ref.read(clientRepositoryProvider);
                        final clientData =
                            await clientRepo.getClient(project.refCliente);
                        final items = productsAsync.value ?? [];
                        if (context.mounted) {
                          await ProjectMaterialsPdfGenerator.generate(
                            project: project,
                            client: clientData,
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
          _buildHeader(context, project, invoiceDetailsAsync.asData?.value,
              client, isMobile),
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
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppStyles.primaryOrange
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.home_work_outlined,
                                              color: AppStyles.primaryOrange),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                poleBarn.poleBarnName ??
                                                    'Estructura',
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
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildProductStatusDropdown(
                                          ref, poleBarn),
                                    )
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppStyles.primaryOrange
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.home_work_outlined,
                                              color: AppStyles.primaryOrange),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              poleBarn.poleBarnName ??
                                                  'Estructura',
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
                                    _buildProductStatusDropdown(ref, poleBarn),
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
      BuildContext context,
      ProjectModel project,
      Map<String, dynamic>? invoiceDetails,
      ClientSimpleModel? client,
      bool isMobile) {
    // Determine Address: prioritize Invoice Address, then physical address, fallback to client address
    final address = invoiceDetails?['Address'] ??
        ((project.direccion != null && project.direccion!.isNotEmpty)
            ? project.direccion!
            : (client?.address ?? 'No disponible'));

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
          if (isMobile) ...[
            _buildInfoRow(Icons.location_on_outlined, 'Dirección', address),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.person_outline, 'Cliente', client?.fullName ?? 'N/A',
                isLink: true, onTap: () {
              if (client != null && client.id.isNotEmpty) {
                context.go('/clients/${client.id}');
              }
            }),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.phone_outlined, 'Teléfono', client?.phone ?? 'N/A',
                isLink: true, onTap: () async {
              if (client?.phone != null) {
                final Uri url = Uri.parse('tel:${client!.phone}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            }),
            const SizedBox(height: 24),
            _buildInfoRow(
                Icons.group_outlined, 'Grupo', project.grupoAsignado ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.manage_accounts_outlined, 'Responsable',
                project.responsable ?? 'N/A'),
            const SizedBox(height: 16),
            _buildStatusPill('Estatus', project.estatus ?? "N/A"),
            const SizedBox(height: 24),
            _buildInfoRow(
                Icons.calendar_today_outlined, 'Fecha Inicio', startDate),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.event_available_outlined, 'Fecha Fin', endDate),
          ] else ...[
            // Row 1: 3 Columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildInfoRow(
                        Icons.location_on_outlined, 'Dirección', address)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInfoRow(Icons.person_outline, 'Cliente',
                        client?.fullName ?? 'N/A',
                        isLink: true, onTap: () {
                  if (client != null && client.id.isNotEmpty) {
                    context.go('/clients/${client.id}');
                  }
                })),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInfoRow(Icons.phone_outlined, 'Teléfono',
                        client?.phone ?? 'N/A',
                        isLink: true, onTap: () async {
                  if (client?.phone != null) {
                    final Uri url = Uri.parse('tel:${client!.phone}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                })),
              ],
            ),
            const SizedBox(height: 24),
            // Row 2: 3 Columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildInfoRow(Icons.group_outlined, 'Grupo',
                        project.grupoAsignado ?? 'N/A')),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInfoRow(Icons.manage_accounts_outlined,
                        'Responsable', project.responsable ?? 'N/A')),
                const SizedBox(width: 16),
                Expanded(
                    child:
                        _buildStatusPill('Estatus', project.estatus ?? "N/A")),
              ],
            ),
            const SizedBox(height: 24),
            // Row 3: 2 Columns + Spacer
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
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Row 4: Comments (Full Width)
          _buildInfoRow(
              Icons.comment_outlined, 'Comentarios', project.comments ?? 'N/A',
              maxLines: 5),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {int maxLines = 1, bool isLink = false, VoidCallback? onTap}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: isLink ? Colors.blue : null,
                    decoration: isLink ? TextDecoration.underline : null,
                    decorationColor: isLink ? Colors.blue : null),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: content,
        ),
      );
    }

    return content;
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
        }),
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

  Widget _buildProductStatusDropdown(
      WidgetRef ref, ProjectPoleBarnModel poleBarn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(poleBarn.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _getStatusColor(poleBarn.status).withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: poleBarn.status,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 18, color: _getStatusColor(poleBarn.status)),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(poleBarn.status),
          ),
          onChanged: (String? newValue) async {
            if (newValue != null && newValue != poleBarn.status) {
              await ref
                  .read(projectRepositoryProvider)
                  .updateProjectPoleBarnStatus(
                      poleBarn.id, newValue, poleBarn.projectId);
              ref.invalidate(
                  projectPoleBarnsMaterialsProvider(poleBarn.projectId));
            }
          },
          items: <String>['Pendiente', 'En Proceso', 'Terminado']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, String status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terminado':
        return Colors.green;
      case 'En Proceso':
        return Colors.blue;
      case 'Pendiente':
      default:
        return Colors.orange;
    }
  }
}
