import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_styles.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  final void Function(String clientId, Map<String, dynamic> client)?
      onCreateEstimate;
  const ClientsListScreen({super.key, this.onCreateEstimate});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  String _searchQuery = '';
  int _sortColumnIndex = 1; // Default by Name
  bool _isAscending = true;
  final Set<String> _selectedIds = {};

  // Pagination
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  Color _getAvatarBgColor(String name) {
    final colors = [
      const Color(0xFFD1FAE5), // Light green
      const Color(0xFFFEF3C7), // Light yellow/orange
      const Color(0xFFE0E7FF), // Light indigo
      const Color(0xFFF3F4F6), // Light grey
      const Color(0xFFFEE2E2), // Light red
    ];
    return colors[name.length % colors.length];
  }

  Color _getAvatarTextColor(String name) {
    final colors = [
      const Color(0xFF065F46), // Dark green
      const Color(0xFF92400E), // Dark yellow/orange
      const Color(0xFF3730A3), // Dark indigo
      const Color(0xFF374151), // Dark grey
      const Color(0xFF991B1B), // Dark red
    ];
    return colors[name.length % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(clientRepositoryProvider);

    return Scaffold(
      backgroundColor: AppStyles.stoneWhite,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<List<ClientModel>>(
            stream: repository.getClientsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final clients = snapshot.data!;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                        child: Text(
                          'Directorio de Clientes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.28,
                            fontFamily: 'Manrope',
                            color: AppStyles.primaryForest,
                          ),
                        ),
                      ),
                      // Toolbar
                      _buildToolbar(context, clients, repository),

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
                              border:
                                  Border.all(color: AppStyles.paleSage),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Builder(builder: (context) {
                              final filtered =
                                  _getFilteredAndSortedClients(clients);
                              final totalItems = filtered.length;
                              final totalPages =
                                  (totalItems / _rowsPerPage).ceil();
                              final startIndex = _currentPage * _rowsPerPage;
                              final endIndex =
                                  (startIndex + _rowsPerPage < totalItems)
                                      ? startIndex + _rowsPerPage
                                      : totalItems;
                              final pagedClients = (totalItems > 0)
                                  ? filtered.sublist(startIndex, endIndex)
                                  : <ClientModel>[];

                              final isMobile = constraints.maxWidth < 650;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: isMobile
                                        ? _buildMobileList(
                                            pagedClients, repository)
                                        : SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth:
                                                    constraints.maxWidth - 48,
                                              ),
                                              child: DataTable(
                                                  showCheckboxColumn: true,
                                                  sortColumnIndex:
                                                      _sortColumnIndex,
                                                  sortAscending: _isAscending,
                                                  headingTextStyle:
                                                      const TextStyle(
                                                    fontWeight: FontWeight.w600, // Semibold
                                                    fontSize: 12,
                                                    color: AppStyles.subLabelColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  dataRowMinHeight: 72,
                                                  dataRowMaxHeight: 72,
                                                  horizontalMargin: 24,
                                                  columnSpacing: 32,
                                                  dividerThickness: 1,
                                                  onSelectAll: (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedIds.addAll(
                                                            pagedClients.map(
                                                                (e) => e.id));
                                                      } else {
                                                        _selectedIds.clear();
                                                      }
                                                    });
                                                  },
                                                  columns: [
                                                    if (constraints.maxWidth > 750)
                                                      const DataColumn(
                                                          label: Text('AVATAR')),
                                                    DataColumn(
                                                        label: const Text(
                                                            'NOMBRE'),
                                                        onSort: _sort),
                                                    if (constraints.maxWidth > 1050)
                                                      const DataColumn(
                                                          label:
                                                              Text('CONTACTO')),
                                                    if (constraints.maxWidth > 850)
                                                      DataColumn(
                                                          label: const Text(
                                                              'DIRECCIÓN'),
                                                          onSort: _sort),
                                                    const DataColumn(
                                                        label: Text('ACCIONES',
                                                            textAlign:
                                                                TextAlign.end)),
                                                  ],
                                                  rows: pagedClients
                                                      .map((client) {
                                                    final isSelected =
                                                        _selectedIds.contains(
                                                            client.id);
                                                    return DataRow(
                                                      selected: isSelected,
                                                      onSelectChanged: (val) {
                                                        setState(() {
                                                          if (val == true) {
                                                            _selectedIds
                                                                .add(client.id);
                                                          } else {
                                                            _selectedIds.remove(
                                                                client.id);
                                                          }
                                                        });
                                                      },
                                                      cells: [
                                                        if (constraints.maxWidth > 750)
                                                          DataCell(
                                                            Container(
                                                              width: 40,
                                                              height: 40,
                                                              decoration: BoxDecoration(
                                                                color: _getAvatarBgColor(client.nombre),
                                                                borderRadius: BorderRadius.circular(8),
                                                                image: client.photoUrl != null
                                                                    ? DecorationImage(
                                                                        image: NetworkImage(client.photoUrl!),
                                                                        fit: BoxFit.cover,
                                                                      )
                                                                    : null,
                                                              ),
                                                              alignment: Alignment.center,
                                                              child: client.photoUrl == null
                                                                  ? Text(
                                                                      _getInitials(client.nombre),
                                                                      style: TextStyle(
                                                                        color: _getAvatarTextColor(client.nombre),
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    )
                                                                  : null,
                                                            ),
                                                          ),
                                                        DataCell(
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                client.nombre,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 14,
                                                                  color: Color(0xFF111827),
                                                                ),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                'Client ID: #${client.id.substring(0, 4)}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF6B7280),
                                                                ),
                                                              ),
                                                              if (constraints.maxWidth <= 1050 && (client.email != null || client.telefono != null)) ...[
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  '${client.email ?? ''}${client.email != null && client.telefono != null ? " • " : ""}${client.telefono ?? ""}',
                                                                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                              if (constraints.maxWidth <= 850 && client.direccion != null) ...[
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  client.direccion!,
                                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                          onTap: () =>
                                                              _navigateToDetail(
                                                                  client.id),
                                                        ),
                                                        if (constraints.maxWidth > 1050)
                                                          DataCell(
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                if (client.email != null && client.email!.isNotEmpty)
                                                                  Text(
                                                                    client.email!,
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Color(0xFF374151),
                                                                    ),
                                                                  ),
                                                                if (client.telefono != null && client.telefono!.isNotEmpty) ...[
                                                                  if (client.email != null && client.email!.isNotEmpty)
                                                                    const SizedBox(height: 4),
                                                                  Text(
                                                                    client.telefono!,
                                                                    style: const TextStyle(
                                                                      fontSize: 12,
                                                                      color: Color(0xFF6B7280),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            onTap: () =>
                                                                _navigateToDetail(
                                                                    client.id),
                                                          ),
                                                        if (constraints.maxWidth > 850)
                                                          DataCell(
                                                            Builder(
                                                              builder: (context) {
                                                                String mainAddr = '-';
                                                                String subAddr = '';
                                                                if (client.direccion != null && client.direccion!.isNotEmpty) {
                                                                  final parts = client.direccion!.split(',');
                                                                  mainAddr = parts[0].trim();
                                                                  if (parts.length > 1) {
                                                                    subAddr = parts.sublist(1).join(',').trim();
                                                                  }
                                                                }
                                                                return Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Text(
                                                                      mainAddr,
                                                                      style: const TextStyle(
                                                                        fontSize: 14,
                                                                        color: Color(0xFF374151),
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    if (subAddr.isNotEmpty) ...[
                                                                      const SizedBox(height: 4),
                                                                      Text(
                                                                        subAddr,
                                                                        style: const TextStyle(
                                                                          fontSize: 12,
                                                                          color: Color(0xFF6B7280),
                                                                        ),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ],
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                            onTap: () =>
                                                                _navigateToDetail(
                                                                    client.id),
                                                          ),
                                                        DataCell(
                                                          Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child:
                                                                _buildActionMenu(
                                                                    client,
                                                                    repository),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          _buildPaginationFooter(startIndex, endIndex,
                                      totalItems, totalPages, isMobile),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, List<ClientModel> clients, dynamic repository) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (_selectedIds.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: isMobile ? null : 56,
        decoration: BoxDecoration(
          color: AppStyles.secondaryEarth.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border:
              Border.all(color: AppStyles.secondaryEarth.withValues(alpha: 0.3)),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedIds.length} seleccionados',
                        style: const TextStyle(
                          color: AppStyles.secondaryEarth,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedIds.clear()),
                        icon: const Icon(Icons.close,
                            size: 20, color: AppStyles.secondaryEarth),
                        label: const Text('Cancelar',
                            style: TextStyle(color: AppStyles.secondaryEarth)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _deleteSelectedClients(repository),
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
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
              )
            : Row(
                children: [
                  Text(
                    '${_selectedIds.length} seleccionados',
                    style: const TextStyle(
                      color: AppStyles.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    icon: const Icon(Icons.close,
                        size: 20, color: AppStyles.primaryOrange),
                    label: const Text('Cancelar',
                        style: TextStyle(color: AppStyles.primaryOrange)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _deleteSelectedClients(repository),
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
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
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppStyles.paleSage),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // New Client Button
                ElevatedButton.icon(
                  onPressed: () => context.go('/clients/new'),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Nuevo Cliente',
                      style: TextStyle(color: Colors.white)),
                  style: AppStyles.primaryButtonStyle,
                ),
              ],
            )
          : Row(
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
                        hintText:
                            'Buscar cliente por nombre, email o teléfono...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade400, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // New Client Button
                ElevatedButton.icon(
                  onPressed: () => context.go('/clients/new'),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Nuevo Cliente',
                      style: TextStyle(color: Colors.white)),
                  style: AppStyles.primaryButtonStyle,
                ),
              ],
            ),
    );
  }

  Widget _buildActionMenu(ClientModel client, dynamic repository) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          context.go('/clients/${client.id}');
        } else if (value == 'delete') {
          _confirmDeleteSingle(client, repository);
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

  List<ClientModel> _getFilteredAndSortedClients(List<ClientModel> all) {
    var filtered = all.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = c.nombre.toLowerCase().contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            (c.telefono?.contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 1:
          cmp = a.nombre.compareTo(b.nombre);
          break;
        case 3:
          cmp = (a.direccion ?? '').compareTo(b.direccion ?? '');
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

  void _navigateToDetail(String id) {
    context.go('/clients/$id');
  }

  Future<void> _deleteSelectedClients(dynamic repository) async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Clientes'),
        content: Text(
            '¿Estás seguro de eliminar ${_selectedIds.length} clientes seleccionados? Esta acción no se puede deshacer.'),
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
        // Bulk delete simulation by iterating
        for (var id in _selectedIds) {
          await repository.deleteClient(id);
        }
        setState(() {
          _selectedIds.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clientes eliminados correctamente')),
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

  Future<void> _confirmDeleteSingle(
      ClientModel client, dynamic repository) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text(
            '¿Estás seguro de eliminar a ${client.nombre}? Esta acción no se puede deshacer.'),
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
        await repository.deleteClient(client.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado correctamente')),
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
      int startIndex, int endIndex, int totalItems, int totalPages, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppStyles.paleSage)),
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  'Mostrando ${totalItems == 0 ? 0 : startIndex + 1} a $endIndex de $totalItems resultados',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
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
              ],
            )
          : Row(
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

  Widget _buildMobileList(List<ClientModel> pagedClients, dynamic repository) {
    if (pagedClients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No se encontraron clientes.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.builder(
      itemCount: pagedClients.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final client = pagedClients[index];
        final isSelected = _selectedIds.contains(client.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color:
                    isSelected ? AppStyles.primaryOrange : Colors.grey.shade200,
                width: isSelected ? 2 : 1),
          ),
          child: InkWell(
            onTap: () {
              if (_selectedIds.isNotEmpty) {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(client.id);
                  } else {
                    _selectedIds.add(client.id);
                  }
                });
              } else {
                _navigateToDetail(client.id);
              }
            },
            onLongPress: () {
              setState(() {
                if (!isSelected) _selectedIds.add(client.id);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getAvatarBgColor(client.nombre),
                          borderRadius: BorderRadius.circular(8),
                          image: client.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(client.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: client.photoUrl == null
                            ? Text(
                                _getInitials(client.nombre),
                                style: TextStyle(
                                  color: _getAvatarTextColor(client.nombre),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF111827))),
                            if (client.email != null) ...[
                              const SizedBox(height: 2),
                              Text(client.email!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF4B5563))),
                            ],
                            if (client.telefono != null) ...[
                              const SizedBox(height: 2),
                              Text(client.telefono!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ],
                        ),
                      ),
                      _buildActionMenu(client, repository),
                    ],
                  ),
                  if (client.direccion != null &&
                      client.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(client.direccion!,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF4B5563)))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
