import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/app_styles.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';
import '../widgets/project_create_dialog.dart';
import 'project_detail_screen.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _isAscending = false;
  final Set<String> _selectedIds = {}; // Projects use String ID

  // Pagination
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  // Filters
  String _statusFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: 1400), // Slightly wider for more columns
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Stats Row
                  projectsAsync.when(
                    data: (list) => _buildStatsHeader(list),
                    loading: () => const SizedBox(height: 100),
                    error: (_, __) => const SizedBox(),
                  ),

                  // Toolbar
                  _buildToolbar(context, projectsAsync.valueOrNull),

                  // Table
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 8.0),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: projectsAsync.when(
                          data: (projects) {
                            final filtered = _getFilteredAndSortedProjects(
                                projects, clientsAsync.valueOrNull);
                            final totalItems = filtered.length;
                            final totalPages =
                                (totalItems / _rowsPerPage).ceil();
                            final startIndex = _currentPage * _rowsPerPage;
                            final endIndex =
                                (startIndex + _rowsPerPage < totalItems)
                                    ? startIndex + _rowsPerPage
                                    : totalItems;
                            final pagedProjects = (totalItems > 0)
                                ? filtered.sublist(startIndex, endIndex)
                                : <ProjectModel>[];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth - 48,
                                        ),
                                        child: DataTable(
                                          showCheckboxColumn: true,
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _isAscending,
                                          headingTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            letterSpacing: 0.5,
                                          ),
                                          dataRowMinHeight: 64,
                                          dataRowMaxHeight: 64,
                                          horizontalMargin: 24,
                                          columnSpacing: 24,
                                          onSelectAll: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedIds.addAll(
                                                    pagedProjects
                                                        .map((e) => e.id));
                                              } else {
                                                _selectedIds.clear();
                                              }
                                            });
                                          },
                                          columns: [
                                            DataColumn(
                                                label: const Text('PROYECTO'),
                                                onSort: (i, b) =>
                                                    _sort(i, b, 0)),
                                            DataColumn(
                                                label: const Text('CLIENTE'),
                                                onSort: (i, b) =>
                                                    _sort(i, b, 1)),
                                            DataColumn(
                                                label: const Text('ESTATUS'),
                                                onSort: (i, b) =>
                                                    _sort(i, b, 2)),
                                            DataColumn(
                                                label: const Text('FECHAS'),
                                                onSort: (i, b) =>
                                                    _sort(i, b, 3)),
                                            DataColumn(
                                                label: const Text('VENTA'),
                                                numeric: true,
                                                onSort: (i, b) =>
                                                    _sort(i, b, 4)),
                                            DataColumn(
                                                label: const Text('COSTOS'),
                                                numeric: true,
                                                onSort: (i, b) =>
                                                    _sort(i, b, 5)),
                                            DataColumn(
                                                label: const Text('PROFIT'),
                                                numeric: true,
                                                onSort: (i, b) =>
                                                    _sort(i, b, 6)),
                                            const DataColumn(
                                                label: Text('ACCIONES',
                                                    textAlign: TextAlign.end)),
                                          ],
                                          rows: pagedProjects.map((project) {
                                            final isSelected = _selectedIds
                                                .contains(project.id);
                                            final clientName = clientsAsync
                                                    .valueOrNull
                                                    ?.firstWhere(
                                                        (c) =>
                                                            c.id ==
                                                            project.refCliente,
                                                        orElse: () =>
                                                            ClientSimpleModel(
                                                                id: '',
                                                                firstName:
                                                                    'Unknown',
                                                                lastName: ''))
                                                    .fullName ??
                                                'Unknown';

                                            return DataRow(
                                              selected: isSelected,
                                              onSelectChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedIds
                                                        .add(project.id);
                                                  } else {
                                                    _selectedIds
                                                        .remove(project.id);
                                                  }
                                                });
                                              },
                                              cells: [
                                                DataCell(
                                                  SizedBox(
                                                    width: 200,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                            project.address ??
                                                                'Sin Nombre',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF111827)),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis),
                                                        Text(
                                                            '#${project.id.substring(0, 8)}...',
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey)),
                                                      ],
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          project.id),
                                                ),
                                                DataCell(
                                                  Text(clientName,
                                                      style: const TextStyle(
                                                          color: Color(
                                                              0xFF4B5563))),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          project.id),
                                                ),
                                                DataCell(
                                                  _buildStatusBadge(project),
                                                ),
                                                DataCell(
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          project.fechaInicio !=
                                                                  null
                                                              ? DateFormat(
                                                                      'MM/dd/yy')
                                                                  .format(project
                                                                      .fechaInicio!)
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                      if (project
                                                              .fechaFinalizacion !=
                                                          null)
                                                        Text(
                                                            DateFormat(
                                                                    'MM/dd/yy')
                                                                .format(project
                                                                    .fechaFinalizacion!),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey)),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(Text(NumberFormat
                                                        .simpleCurrency()
                                                    .format(
                                                        project.ventaTotal))),
                                                DataCell(Text(
                                                    NumberFormat
                                                            .simpleCurrency()
                                                        .format(project
                                                            .costosTotales),
                                                    style: const TextStyle(
                                                        color:
                                                            Colors.redAccent))),
                                                DataCell(Text(
                                                    NumberFormat
                                                            .simpleCurrency()
                                                        .format(project.profit),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green))),
                                                DataCell(
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: _buildActionMenu(
                                                        project),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildPaginationFooter(startIndex, endIndex,
                                    totalItems, totalPages),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('Error: $e')),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<ProjectModel> projects) {
    // Only count active projects for these stats? Or all? Let's do all.
    final totalVentas =
        projects.fold<double>(0, (sum, item) => sum + item.ventaTotal);
    final totalCostos =
        projects.fold<double>(0, (sum, item) => sum + item.costosTotales);
    final totalProfit =
        projects.fold<double>(0, (sum, item) => sum + item.profit);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          _buildStatCard('TOTAL VENDIDO', totalVentas, Colors.black87),
          const SizedBox(width: 24),
          _buildStatCard('TOTAL GASTADO', totalCostos, Colors.redAccent),
          const SizedBox(width: 24),
          _buildStatCard('GANANCIA ESTIMADA', totalProfit, Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color) {
    final currency = NumberFormat.simpleCurrency();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(currency.format(amount),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, List<ProjectModel>? projects) {
    if (_selectedIds.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 56,
        decoration: BoxDecoration(
          color: AppStyles.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppStyles.primaryOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} seleccionados',
              style: TextStyle(
                color: AppStyles.primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _selectedIds.clear()),
              icon: Icon(Icons.close, size: 20, color: AppStyles.primaryOrange),
              label: Text('Cancelar',
                  style: TextStyle(color: AppStyles.primaryOrange)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelected,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar proyecto...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Filters
          _buildFilterChip(),
          const SizedBox(width: 16),

          // New Project Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const ProjectCreateDialog(),
              );
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nuevo Proyecto',
                style: TextStyle(color: Colors.white)),
            style: AppStyles.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _statusFilter = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Todos', child: Text('Todos los estados')),
        const PopupMenuItem(value: 'En Proceso', child: Text('En Proceso')),
        const PopupMenuItem(value: 'Terminado', child: Text('Terminado')),
        const PopupMenuItem(value: 'Pendiente', child: Text('Pendiente')),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _statusFilter != 'Todos'
                  ? AppStyles.primaryOrange
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list,
                size: 18,
                color: _statusFilter != 'Todos'
                    ? AppStyles.primaryOrange
                    : Colors.grey),
            const SizedBox(width: 8),
            Text(
              _statusFilter,
              style: TextStyle(
                fontSize: 13,
                color: _statusFilter != 'Todos'
                    ? AppStyles.primaryOrange
                    : Colors.black87,
                fontWeight: _statusFilter != 'Todos'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProjectModel project) {
    Color color = Colors.grey;
    if (project.estatus == 'Terminado') color = const Color(0xFF059669);
    if (project.estatus == 'En Proceso') color = const Color(0xFFD97706);
    if (project.estatus == 'Pendiente') color = const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        (project.estatus ?? 'UNKNOWN').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionMenu(ProjectModel project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) async {
        if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar Proyecto'),
              content: const Text(
                  '¿Estás seguro de eliminar este proyecto y todos sus datos relacionados?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(projectRepositoryProvider).deleteProject(project.id);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  List<ProjectModel> _getFilteredAndSortedProjects(
      List<ProjectModel> all, List<ClientSimpleModel>? clients) {
    var filtered = all.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        // Resolve client name
        final cName = clients
                ?.firstWhere((c) => c.id == p.refCliente,
                    orElse: () =>
                        ClientSimpleModel(id: '', firstName: '', lastName: ''))
                .fullName
                .toLowerCase() ??
            '';

        final match = (p.address?.toLowerCase().contains(q) ?? false) ||
            cName.contains(q);
        if (!match) return false;
      }
      if (_statusFilter != 'Todos') {
        if (p.estatus != _statusFilter) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      // Resolve client name for sorting
      final cNameA = clients
              ?.firstWhere((c) => c.id == a.refCliente,
                  orElse: () =>
                      ClientSimpleModel(id: '', firstName: '', lastName: ''))
              .fullName ??
          '';
      final cNameB = clients
              ?.firstWhere((c) => c.id == b.refCliente,
                  orElse: () =>
                      ClientSimpleModel(id: '', firstName: '', lastName: ''))
              .fullName ??
          '';

      switch (_sortColumnIndex) {
        case 0: // Project Name
          cmp = (a.address ?? '').compareTo(b.address ?? '');
          break;
        case 1: // Client
          cmp = cNameA.compareTo(cNameB);
          break;
        case 2: // Status
          cmp = (a.estatus ?? '').compareTo(b.estatus ?? '');
          break;
        case 3: // Dates (Start)
          cmp = (a.fechaInicio ?? DateTime.now())
              .compareTo(b.fechaInicio ?? DateTime.now());
          break;
        case 4: // Venta
          cmp = a.ventaTotal.compareTo(b.ventaTotal);
          break;
        case 5: // Costos
          cmp = a.costosTotales.compareTo(b.costosTotales);
          break;
        case 6: // Profit
          cmp = a.profit.compareTo(b.profit);
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _sort(int columnIndex, bool ascending, int _) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  void _navigateToDetail(String id) {
    // In new UI, we push to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(projectId: id),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proyectos'),
        content: Text(
            '¿Estás seguro de eliminar ${_selectedIds.length} proyectos seleccionados?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar Todo',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(projectRepositoryProvider);
      try {
        for (final id in _selectedIds) {
          await repo.deleteProject(id);
        }
        setState(() => _selectedIds.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proyectos eliminados')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildPaginationFooter(
      int startIndex, int endIndex, int totalItems, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(
            'Mostrando ${totalItems == 0 ? 0 : startIndex + 1} a $endIndex de $totalItems resultados',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Página ${_currentPage + 1} de $totalPages',
              style: const TextStyle(fontSize: 13)),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
