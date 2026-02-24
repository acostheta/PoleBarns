import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';
import 'user_detail_screen.dart';
import 'user_form_screen.dart';
import 'group_form_dialog.dart';
import 'dart:async';

enum UsersView { workers, groups }

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  UsersView _currentView = UsersView.workers;
  String _searchQuery = '';

  // Sorting state
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Pagination state
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  // Selection
  final Set<String> _selectedIds = {};

  // Filters
  String _roleFilter = 'Todos';
  String _statusFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final groupsAsync = ref.watch(workerGroupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Header & Stats
              _buildHeader(),

              // Toolbar
              _buildToolbar(context),

              // Content (Table)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 8.0),
                  child: Container(
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
                    clipBehavior: Clip.antiAlias,
                    child: _currentView == UsersView.workers
                        ? _buildUsersTable(usersAsync)
                        : _buildGroupsTable(groupsAsync, usersAsync),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Personal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administra trabajadores, roles y grupos de trabajo.',
                  style: TextStyle(color: AppColors.stone500),
                ),
                const SizedBox(height: 16),
                // View Switcher (Tabs)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.stone200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewTab('Trabajadores', UsersView.workers),
                      const SizedBox(width: 4),
                      _buildViewTab('Grupos', UsersView.groups),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestión de Personal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administra trabajadores, roles y grupos de trabajo.',
                      style: TextStyle(color: AppColors.stone500),
                    ),
                  ],
                ),

                // View Switcher (Tabs)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.stone200),
                  ),
                  child: Row(
                    children: [
                      _buildViewTab('Trabajadores', UsersView.workers),
                      const SizedBox(width: 4),
                      _buildViewTab('Grupos', UsersView.groups),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildViewTab(String label, UsersView view) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () => setState(() {
        _currentView = view;
        _searchQuery = '';
        _selectedIds.clear();
        _currentPage = 0;
      }),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.stone500,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (_selectedIds.isNotEmpty && _currentView == UsersView.workers) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} seleccionados',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _selectedIds.clear()),
              icon: const Icon(Icons.close, size: 20, color: AppColors.primary),
              label: const Text('Cancelar',
                  style: TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            // Could add bulk actions here later
          ],
        ),
      );
    }

    final searchField = Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _currentPage = 0;
        }),
        decoration: InputDecoration(
          hintText: _currentView == UsersView.workers
              ? 'Buscar por nombre, email...'
              : 'Buscar grupos...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    final actionButton = ElevatedButton.icon(
      onPressed: () {
        if (_currentView == UsersView.workers) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UserFormScreen()));
        } else {
          _showCreateGroupDialog();
        }
      },
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(
        _currentView == UsersView.workers ? 'Nuevo Trabajador' : 'Nuevo Grupo',
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            searchField,
            const SizedBox(height: 16),
            if (_currentView == UsersView.workers) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton('Rol: $_roleFilter', () {
                    setState(() {
                      _roleFilter = _roleFilter == 'Todos'
                          ? 'Administrador'
                          : (_roleFilter == 'Administrador'
                              ? 'Trabajador'
                              : 'Todos');
                      _currentPage = 0;
                    });
                  }),
                  _buildFilterButton('Estado: $_statusFilter', () {
                    setState(() {
                      _statusFilter = _statusFilter == 'Todos'
                          ? 'Activo'
                          : (_statusFilter == 'Activo' ? 'Inactivo' : 'Todos');
                      _currentPage = 0;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: actionButton,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(child: searchField),
          if (_currentView == UsersView.workers) ...[
            const SizedBox(width: 16),
            _buildFilterButton('Rol: $_roleFilter', () {
              setState(() {
                _roleFilter = _roleFilter == 'Todos'
                    ? 'Administrador'
                    : (_roleFilter == 'Administrador' ? 'Trabajador' : 'Todos');
                _currentPage = 0;
              });
            }),
            const SizedBox(width: 16),
            _buildFilterButton('Estado: $_statusFilter', () {
              setState(() {
                _statusFilter = _statusFilter == 'Todos'
                    ? 'Activo'
                    : (_statusFilter == 'Activo' ? 'Inactivo' : 'Todos');
                _currentPage = 0;
              });
            }),
          ],
          const SizedBox(width: 16),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.filter_list, size: 16, color: AppColors.stone500),
      label: Text(label,
          style: const TextStyle(color: AppColors.stone600, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.stone500,
        side: const BorderSide(color: AppColors.stone300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildUsersTable(AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    return usersAsync.when(
      data: (users) {
        // Filter
        var filtered = users.where((u) {
          final query = _searchQuery.toLowerCase();
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();

          final matchSearch = name.contains(query) || email.contains(query);

          final role = u['role'] ?? 'Sin rol';
          final isActive = u['is_active'] == true;

          final matchRole = _roleFilter == 'Todos' || role == _roleFilter;
          final matchStatus = _statusFilter == 'Todos' ||
              (_statusFilter == 'Activo' ? isActive : !isActive);

          return matchSearch && matchRole && matchStatus;
        }).toList();

        // Sort
        filtered.sort((a, b) {
          int cmp = 0;
          switch (_sortColumnIndex) {
            case 0:
              cmp = (a['name'] ?? '').compareTo(b['name'] ?? '');
              break;
            case 1:
              cmp = (a['email'] ?? '').compareTo(b['email'] ?? '');
              break;
            case 2:
              cmp = (a['role'] ?? '').compareTo(b['role'] ?? '');
              break;
            // case 3: job position requires lookup, simplified for now
            default:
              cmp = 0;
          }
          return _isAscending ? cmp : -cmp;
        });

        // Paginate
        final totalItems = filtered.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();

        // Safety check for current page
        if (_currentPage >= totalPages && totalPages > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentPage >= totalPages) {
              setState(() {
                _currentPage = totalPages - 1;
              });
            }
          });
        }

        final displayPage = (_currentPage >= totalPages && totalPages > 0)
            ? totalPages - 1
            : _currentPage;

        final startIndex = displayPage * _rowsPerPage;
        var endIndex = startIndex + _rowsPerPage;
        if (endIndex > totalItems) endIndex = totalItems;

        final pagedUsers = (totalItems > 0 && startIndex < totalItems)
            ? filtered.sublist(startIndex, endIndex)
            : <Map<String, dynamic>>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: true,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _isAscending,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.stone500),
                    onSelectAll: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.addAll(pagedUsers.map((u) => u['id']));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                    columns: [
                      DataColumn(label: const Text('NOMBRE'), onSort: _onSort),
                      DataColumn(label: const Text('EMAIL'), onSort: _onSort),
                      DataColumn(label: const Text('ROL'), onSort: _onSort),
                      const DataColumn(label: Text('ESTADO')),
                      const DataColumn(label: Text('ACCIONES')),
                    ],
                    rows: pagedUsers.map((user) {
                      final isSelected = _selectedIds.contains(user['id']);
                      final isActive = user['is_active'] == true;
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (val) {
                          setState(() {
                            if (val == true)
                              _selectedIds.add(user['id']);
                            else
                              _selectedIds.remove(user['id']);
                          });
                        },
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.stone200,
                                  backgroundImage: user['picture'] != null
                                      ? NetworkImage(user['picture'])
                                      : null,
                                  child: user['picture'] == null
                                      ? Text(
                                          ((user['name'] != null &&
                                                      user['name']
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? user['name'][0]
                                                  : 'U')
                                              .toUpperCase(),
                                          style: const TextStyle(fontSize: 12))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(user['name'] ?? 'Sin Nombre',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            onTap: () => _navigateToDetail(user['id']),
                          ),
                          DataCell(
                            Text(user['email'] ?? '-'),
                            onTap: () => _navigateToDetail(user['id']),
                          ),
                          DataCell(
                            _buildRoleBadge(user['role'] ?? 'Sin rol'),
                            onTap: () => _navigateToDetail(user['id']),
                          ),
                          DataCell(
                            _buildStatusBadge(isActive),
                            onTap: () => _navigateToDetail(user['id']),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppColors.primary, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => UserFormScreen(
                                                userId: user['id'],
                                                userMetadata: user)));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _buildPaginationFooter(
                startIndex, endIndex, totalItems, totalPages),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildGroupsTable(AsyncValue<List<Map<String, dynamic>>> groupsAsync,
      AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    // Similar table for groups
    return groupsAsync.when(
      data: (groups) {
        final users = usersAsync.value ?? [];
        var filtered = groups
            .where((g) => (g['name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.stone500),
                    columns: const [
                      DataColumn(label: Text('NOMBRE DEL GRUPO')),
                      DataColumn(label: Text('RESPONSABLE')),
                      DataColumn(
                          label: Text('MIEMBROS')), // Could count members?
                      DataColumn(label: Text('ACCIONES')),
                    ],
                    rows: filtered.map((group) {
                      final supervisorId = group['supervisor_id'];
                      final supervisorName = users.firstWhere(
                              (u) => u['id'] == supervisorId,
                              orElse: () => {})['name'] ??
                          '-';

                      return DataRow(
                        cells: [
                          DataCell(Text(group['name'] ?? 'Group',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(supervisorName)),
                          DataCell(Consumer(builder: (ctx, ref, _) {
                            final membersAsync =
                                ref.watch(groupMembersProvider(group['id']));
                            return membersAsync.when(
                              data: (m) => Text('${m.length} miembros'),
                              loading: () => const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              error: (_, __) => const Text('-'),
                            );
                          })),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppColors.primary),
                                  onPressed: () => _showEditGroupDialog(group),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteGroup(group['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'Administrador';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.purple.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isAdmin
                ? Colors.purple.withValues(alpha: 0.3)
                : Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.purple : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
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

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  void _navigateToDetail(String id) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => UserDetailScreen(userId: id)));
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => const GroupFormDialog(),
    );
  }

  Future<void> _showEditGroupDialog(Map<String, dynamic> group) async {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(group: group),
    );
  }

  Future<void> _confirmDeleteGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Grupo?'),
        content: const Text(
            'Esta acción eliminará el grupo. No eliminará los usuarios.'),
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
      await ref.read(usersRepositoryProvider).deleteWorkerGroup(groupId);
    }
  }
}
