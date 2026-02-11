import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  String _searchQuery = '';
  int _sortColumnIndex = 3; // Default by Date
  bool _isAscending = false;
  final Set<int> _selectedIds = {};

  // Pagination
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  // Filters
  String _statusFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);
    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat('MM/dd/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Stats Row (only show if not selecting for cleaner look, or keep it)
                  // Keeping it provides context
                  invoicesAsync.when(
                    data: (list) => _buildStatsHeader(list),
                    loading: () => const SizedBox(height: 100),
                    error: (_, __) => const SizedBox(),
                  ),

                  // Toolbar
                  _buildToolbar(context, invoicesAsync.valueOrNull),

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
                        child: invoicesAsync.when(
                          data: (invoices) {
                            final filtered =
                                _getFilteredAndSortedInvoices(invoices);
                            final totalItems = filtered.length;
                            final totalPages =
                                (totalItems / _rowsPerPage).ceil();
                            final startIndex = _currentPage * _rowsPerPage;
                            final endIndex =
                                (startIndex + _rowsPerPage < totalItems)
                                    ? startIndex + _rowsPerPage
                                    : totalItems;
                            final pagedInvoices = (totalItems > 0)
                                ? filtered.sublist(startIndex, endIndex)
                                : <InvoiceModel>[];

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
                                          // Ensure table takes full width of container if content is smaller
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
                                          // Handle Select All
                                          onSelectAll: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedIds.addAll(
                                                    pagedInvoices
                                                        .map((e) => e.id));
                                              } else {
                                                _selectedIds.clear();
                                              }
                                            });
                                          },
                                          columns: [
                                            DataColumn(
                                                label: const Text('ID (#)'),
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('CLIENTE'),
                                                onSort: _sort),
                                            const DataColumn(
                                                label: Text('PROYECTO')),
                                            DataColumn(
                                                label: const Text('FECHA'),
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('TOTAL'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('PAGADO'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('SALDO'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('ESTADO'),
                                                onSort: _sort),
                                            const DataColumn(
                                                label: Text('ACCIONES',
                                                    textAlign: TextAlign.end)),
                                          ],
                                          rows: pagedInvoices.map((invoice) {
                                            final isSelected = _selectedIds
                                                .contains(invoice.id);
                                            return DataRow(
                                              selected: isSelected,
                                              onSelectChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedIds
                                                        .add(invoice.id);
                                                  } else {
                                                    _selectedIds
                                                        .remove(invoice.id);
                                                  }
                                                });
                                              },
                                              cells: [
                                                DataCell(
                                                  Text('#${invoice.id}',
                                                      style: const TextStyle(
                                                          color: Color(
                                                              0xFF4B5563))),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  Text(
                                                      invoice.clientName ??
                                                          'Sin Cliente',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                              0xFF111827))),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  SizedBox(
                                                    width: 180,
                                                    child: Text(
                                                        invoice.projectName ??
                                                            invoice.address ??
                                                            'Sin Proyecto',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .blue[700],
                                                            fontSize: 12)),
                                                  ),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  Text(dateFormat
                                                      .format(invoice.date)),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  Text(currency.format(
                                                      invoice.totalVenta)),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  Text(
                                                      currency.format(
                                                          invoice.totalPagado),
                                                      style: const TextStyle(
                                                          color: Color(
                                                              0xFF059669))),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                  Text(
                                                      currency.format(
                                                          invoice.saldo),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: invoice.saldo >
                                                                  0
                                                              ? const Color(
                                                                  0xFFDC2626)
                                                              : const Color(
                                                                  0xFF111827))),
                                                  onTap: () =>
                                                      _navigateToDetail(
                                                          invoice.id),
                                                ),
                                                DataCell(
                                                    _buildStatusBadge(invoice),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            invoice.id)),
                                                DataCell(
                                                  // Kebab Menu
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: _buildActionMenu(
                                                        invoice),
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

  Widget _buildStatsHeader(List<InvoiceModel> invoices) {
    final totalVenta =
        invoices.fold<double>(0, (sum, item) => sum + item.totalVenta);
    final totalPagado =
        invoices.fold<double>(0, (sum, item) => sum + item.totalPagado);
    final totalSaldo =
        invoices.fold<double>(0, (sum, item) => sum + item.saldo);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          _buildStatCard('TOTAL VENTAS', totalVenta, Colors.black87),
          const SizedBox(width: 24),
          _buildStatCard('TOTAL COBRADO', totalPagado, const Color(0xFF059669)),
          const SizedBox(width: 24),
          _buildStatCard('SALDO PENDIENTE', totalSaldo, Colors.redAccent),
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

  Widget _buildToolbar(BuildContext context, List<InvoiceModel>? invoices) {
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
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _deleteSelectedInvoices,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.white),
              label:
                  const Text('Eliminar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
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
                  hintText: 'Buscar factura por ID, cliente o dirección...',
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

          // Filters button
          _buildFilterChip(),
          const SizedBox(width: 16),

          // New Invoice Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateInvoiceScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nueva Factura',
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
        const PopupMenuItem(value: 'Pagado', child: Text('Solo Pagados')),
        const PopupMenuItem(value: 'Parcial', child: Text('Solo Parciales')),
        const PopupMenuItem(value: 'Pendiente', child: Text('Solo Pendientes')),
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

  Widget _buildStatusBadge(InvoiceModel invoice) {
    final status = _getStatusString(invoice);
    Color color = Colors.grey;
    if (status == 'Pagado') color = const Color(0xFF059669);
    if (status == 'Parcial') color = const Color(0xFFD97706);
    if (status == 'Pendiente') color = const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionMenu(InvoiceModel invoice) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateInvoiceScreen(invoiceId: invoice.id),
            ),
          );
        } else if (value == 'delete') {
          _confirmDeleteSingle(invoice);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
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

  String _getStatusString(InvoiceModel invoice) {
    if (invoice.saldo <= 0) return 'Pagado';
    if (invoice.totalPagado > 0) return 'Parcial';
    return 'Pendiente';
  }

  List<InvoiceModel> _getFilteredAndSortedInvoices(List<InvoiceModel> all) {
    var filtered = all.where((inv) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = inv.id.toString().contains(q) ||
            (inv.clientName?.toLowerCase().contains(q) ?? false) ||
            (inv.address?.toLowerCase().contains(q) ?? false) ||
            (inv.projectName?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      if (_statusFilter != 'Todos') {
        if (_getStatusString(inv) != _statusFilter) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.id.compareTo(b.id);
          break;
        case 1:
          cmp = (a.clientName ?? '').compareTo(b.clientName ?? '');
          break;
        case 3:
          cmp = a.date.compareTo(b.date);
          break;
        case 4:
          cmp = a.totalVenta.compareTo(b.totalVenta);
          break;
        case 5:
          cmp = a.totalPagado.compareTo(b.totalPagado);
          break;
        case 6:
          cmp = a.saldo.compareTo(b.saldo);
          break;
        case 7:
          cmp = _getStatusString(a).compareTo(_getStatusString(b));
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  void _navigateToDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoiceId: id),
      ),
    );
  }

  Future<void> _deleteSelectedInvoices() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Facturas'),
        content: Text(
            '¿Estás seguro de eliminar ${_selectedIds.length} facturas seleccionadas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(invoiceServiceProvider)
            .deleteInvoices(_selectedIds.toList());
        setState(() {
          _selectedIds.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facturas eliminadas correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSingle(InvoiceModel invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text(
            '¿Estás seguro de eliminar la factura #${invoice.id}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(invoiceServiceProvider).deleteInvoice(invoice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factura eliminada correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
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
