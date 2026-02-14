import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/pole_barn_model.dart';
import '../providers/pole_barn_provider.dart';
import 'pole_barn_detail_screen.dart';

class PoleBarnsListScreen extends ConsumerStatefulWidget {
  const PoleBarnsListScreen({super.key});

  @override
  ConsumerState<PoleBarnsListScreen> createState() =>
      _PoleBarnsListScreenState();
}

class _PoleBarnsListScreenState extends ConsumerState<PoleBarnsListScreen> {
  String _searchQuery = '';
  int _sortColumnIndex = 1;
  bool _isAscending = true;
  final Set<int> _selectedIds = {};

  // Pagination
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(poleBarnsListStreamProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Toolbar
                  _buildToolbar(context),

                  // Table Container
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
                        child: productsAsync.when(
                          data: (products) {
                            final filtered = _getFilteredAndSorted(products);
                            final totalItems = filtered.length;
                            final totalPages =
                                (totalItems / _rowsPerPage).ceil();

                            if (_currentPage >= totalPages && totalPages > 0) {
                              _currentPage = totalPages - 1;
                            }

                            final startIndex = _currentPage * _rowsPerPage;
                            final endIndex =
                                (startIndex + _rowsPerPage < totalItems)
                                    ? startIndex + _rowsPerPage
                                    : totalItems;
                            final pagedItems = (totalItems > 0)
                                ? filtered.sublist(startIndex, endIndex)
                                : <PoleBarn>[];

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
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _isAscending,
                                          showCheckboxColumn: false,
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
                                          columns: [
                                            DataColumn(
                                              label: Checkbox(
                                                value: pagedItems.isNotEmpty &&
                                                    pagedItems.every((item) =>
                                                        _selectedIds
                                                            .contains(item.id)),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      for (var item
                                                          in pagedItems) {
                                                        if (item.id != null) {
                                                          _selectedIds
                                                              .add(item.id!);
                                                        }
                                                      }
                                                    } else {
                                                      for (var item
                                                          in pagedItems) {
                                                        _selectedIds
                                                            .remove(item.id);
                                                      }
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            DataColumn(
                                                label: const Text('ID (#)'),
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('NOMBRE'),
                                                onSort: _sort),
                                            const DataColumn(
                                                label: Text('DIMENSIONES')),
                                            DataColumn(
                                                label: const Text('COSTO'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label:
                                                    const Text('PRECIO VENTA'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label:
                                                    const Text('PRESUPUESTO'),
                                                numeric: true,
                                                onSort: _sort),
                                            DataColumn(
                                                label: const Text('ESTADO'),
                                                onSort: _sort),
                                            const DataColumn(
                                                label: Text('ACCIONES')),
                                          ],
                                          rows: pagedItems.map((product) {
                                            final isSelected = _selectedIds
                                                .contains(product.id);
                                            return DataRow(
                                              selected: isSelected,
                                              cells: [
                                                DataCell(
                                                  Checkbox(
                                                    value: isSelected,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        if (val == true) {
                                                          _selectedIds
                                                              .add(product.id!);
                                                        } else {
                                                          _selectedIds.remove(
                                                              product.id);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                                DataCell(
                                                    Text('#${product.id}',
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFF4B5563))),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    Text(product.name ?? 'S/N',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xFF111827))),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    Text(
                                                        '${product.ancho}x${product.largo}x${product.alto}'),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    Text(
                                                        currency.format(
                                                            product.cost),
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFFDC2626),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    Text(
                                                        currency.format(product
                                                            .precioVenta),
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFF059669),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    Text(currency.format(
                                                        product.budgetLimit)),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                    _buildStatusBadge(product),
                                                    onTap: () =>
                                                        _navigateToDetail(
                                                            product)),
                                                DataCell(
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: _buildActionMenu(
                                                        product),
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

  Widget _buildToolbar(BuildContext context) {
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
                  hintText: 'Buscar por nombre o dimensiones...',
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
          ElevatedButton.icon(
            onPressed: () => _navigateToDetail(null),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nuevo Producto',
                style: TextStyle(color: Colors.white)),
            style: AppStyles.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Productos'),
        content: Text(
            '¿Estás seguro de eliminar ${_selectedIds.length} productos seleccionados?'),
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
      final repo = ref.read(poleBarnRepositoryProvider);
      try {
        for (final id in _selectedIds) {
          await repo.deletePoleBarn(id);
        }
        setState(() => _selectedIds.clear());
        ref.invalidate(poleBarnsListStreamProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Productos eliminados')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildStatusBadge(PoleBarn product) {
    final hasAlert = product.alertStatus != 'OK';
    final color = hasAlert ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final text = hasAlert ? 'ALERTA' : 'OK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionMenu(PoleBarn product) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          _navigateToDetail(product);
        } else if (value == 'delete') {
          _confirmDelete(product);
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

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  List<PoleBarn> _getFilteredAndSorted(List<PoleBarn> all) {
    var filtered = all.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = (p.name?.toLowerCase().contains(q) ?? false) ||
            '${p.ancho}x${p.largo}x${p.alto}'.contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.id?.compareTo(b.id ?? 0) ?? 0;
          break;
        case 1:
          cmp = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case 3: // Cost
          cmp = a.cost.compareTo(b.cost);
          break;
        case 4: // Price
          cmp = a.precioVenta.compareTo(b.precioVenta);
          break;
        case 5: // Budget
          cmp = a.budgetLimit.compareTo(b.budgetLimit);
          break;
        case 6: // Status
          cmp = a.alertStatus.compareTo(b.alertStatus);
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _navigateToDetail(PoleBarn? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoleBarnDetailScreen(initialPoleBarn: product),
      ),
    );
  }

  Future<void> _confirmDelete(PoleBarn product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
            '¿Estás seguro de eliminar "${product.name}"? Esta acción no se puede deshacer.'),
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

    if (confirm == true && product.id != null) {
      await ref.read(poleBarnRepositoryProvider).deletePoleBarn(product.id!);
      ref.invalidate(poleBarnsListStreamProvider);
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
