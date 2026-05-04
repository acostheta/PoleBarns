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

  // Branded Colors
  static const Color primaryForest = Color(0xFF173124);
  static const Color secondaryEarth = Color(0xFF7C580F);
  static const Color backgroundLight = Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final groupsAsync = ref.watch(workerGroupsProvider);

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Branded Header
              _buildBrandedHeader(),

              // Toolbar (Search & Actions)
              _buildToolbar(context),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandedHeader() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTitle(),
                const SizedBox(height: 24),
                _buildViewSwitcher(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildHeaderTitle(),
                _buildViewSwitcher(),
              ],
            ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: secondaryEarth,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gestión de Personal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryForest,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Administra trabajadores, roles y grupos de trabajo de J&P Pole Barns.',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewTab('Trabajadores', UsersView.workers, Icons.people_outline),
          const SizedBox(width: 4),
          _buildViewTab('Grupos', UsersView.groups, Icons.group_work_outlined),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, UsersView view, IconData icon) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () => setState(() {
        _currentView = view;
        _searchQuery = '';
        _selectedIds.clear();
        _currentPage = 0;
      }),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? primaryForest : Colors.black.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryForest : Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (_selectedIds.isNotEmpty && _currentView == UsersView.workers) {
      return _buildSelectionToolbar();
    }

    final searchField = Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
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
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: primaryForest.withValues(alpha: 0.4), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final actionButton = FilledButton.icon(
      onPressed: () {
        if (_currentView == UsersView.workers) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserFormScreen()));
        } else {
          _showCreateGroupDialog();
        }
      },
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        _currentView == UsersView.workers ? 'Nuevo Trabajador' : 'Nuevo Grupo',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: primaryForest,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: isMobile
          ? Column(
              children: [
                searchField,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Rol',
                        value: _roleFilter,
                        items: ['Todos', 'Administrador', 'Trabajador'],
                        onChanged: (v) => setState(() => _roleFilter = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        label: 'Estado',
                        value: _statusFilter,
                        items: ['Todos', 'Activo', 'Inactivo'],
                        onChanged: (v) => setState(() => _statusFilter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 16),
                if (_currentView == UsersView.workers) ...[
                  _buildFilterDropdown(
                    label: 'Rol',
                    value: _roleFilter,
                    items: ['Todos', 'Administrador', 'Trabajador'],
                    onChanged: (v) => setState(() => _roleFilter = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(
                    label: 'Estado',
                    value: _statusFilter,
                    items: ['Todos', 'Activo', 'Inactivo'],
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ],
                const SizedBox(width: 16),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildSelectionToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: primaryForest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryForest.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: primaryForest, size: 20),
          const SizedBox(width: 12),
          Text(
            '${_selectedIds.length} seleccionados',
            style: const TextStyle(color: primaryForest, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: const Text('Cancelar', style: TextStyle(color: secondaryEarth)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          icon: Icon(Icons.keyboard_arrow_down, color: primaryForest.withValues(alpha: 0.5)),
          style: const TextStyle(color: primaryForest, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildUsersTable(AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    return usersAsync.when(
      data: (users) {
        var filtered = users.where((u) {
          final query = _searchQuery.toLowerCase();
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          final matchSearch = name.contains(query) || email.contains(query);

          final role = u['role'] ?? 'Sin rol';
          final isActive = u['is_active'] == true;
          final matchRole = _roleFilter == 'Todos' || role == _roleFilter;
          final matchStatus = _statusFilter == 'Todos' || (_statusFilter == 'Activo' ? isActive : !isActive);

          return matchSearch && matchRole && matchStatus;
        }).toList();

        // Sort
        filtered.sort((a, b) {
          int cmp = 0;
          switch (_sortColumnIndex) {
            case 0: cmp = (a['name'] ?? '').compareTo(b['name'] ?? ''); break;
            case 1: cmp = (a['email'] ?? '').compareTo(b['email'] ?? ''); break;
            case 2: cmp = (a['role'] ?? '').compareTo(b['role'] ?? ''); break;
            default: cmp = 0;
          }
          return _isAscending ? cmp : -cmp;
        });

        final totalItems = filtered.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        final displayPage = (_currentPage >= totalPages && totalPages > 0) ? totalPages - 1 : _currentPage;
        final startIndex = displayPage * _rowsPerPage;
        var endIndex = startIndex + _rowsPerPage;
        if (endIndex > totalItems) endIndex = totalItems;
        final pagedUsers = (totalItems > 0 && startIndex < totalItems) ? filtered.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 40,
                    headingRowHeight: 56,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    showCheckboxColumn: true,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _isAscending,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryForest.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    onSelectAll: (val) {
                      setState(() {
                        if (val == true) _selectedIds.addAll(pagedUsers.map((u) => u['id']));
                        else _selectedIds.clear();
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
                            if (val == true) _selectedIds.add(user['id']);
                            else _selectedIds.remove(user['id']);
                          });
                        },
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: secondaryEarth.withValues(alpha: 0.1),
                                  backgroundImage: user['picture'] != null ? NetworkImage(user['picture']) : null,
                                  child: user['picture'] == null
                                      ? Text(
                                          ((user['name'] != null && user['name'].toString().isNotEmpty) ? user['name'][0] : 'U').toUpperCase(),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: secondaryEarth),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  user['name'] ?? 'Sin Nombre',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: primaryForest),
                                ),
                              ],
                            ),
                            onTap: () => _navigateToDetail(user['id']),
                          ),
                          DataCell(Text(user['email'] ?? '-'), onTap: () => _navigateToDetail(user['id'])),
                          DataCell(_buildRoleBadge(user['role'] ?? 'Sin rol'), onTap: () => _navigateToDetail(user['id'])),
                          DataCell(_buildStatusBadge(isActive), onTap: () => _navigateToDetail(user['id'])),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: secondaryEarth, size: 20),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => UserFormScreen(userId: user['id'], userMetadata: user)));
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _buildPaginationFooter(startIndex, endIndex, totalItems, totalPages),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: primaryForest)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildGroupsTable(AsyncValue<List<Map<String, dynamic>>> groupsAsync, AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    return groupsAsync.when(
      data: (groups) {
        final users = usersAsync.value ?? [];
        var filtered = groups.where((g) => (g['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            children: filtered.map((group) {
              final supervisorId = group['supervisor_id'];
              final supervisorName = users.firstWhere((u) => u['id'] == supervisorId, orElse: () => {})['name'] ?? '-';

              return Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group['name'] ?? 'Grupo',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryForest),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: secondaryEarth, size: 20),
                              onPressed: () => _showEditGroupDialog(group),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDeleteGroup(group['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildGroupInfoRow(Icons.person_pin_outlined, 'Supervisor', supervisorName),
                    const SizedBox(height: 12),
                    Consumer(builder: (ctx, ref, _) {
                      final membersAsync = ref.watch(groupMembersProvider(group['id']));
                      return _buildGroupInfoRow(
                        Icons.group_outlined,
                        'Miembros',
                        membersAsync.when(
                          data: (m) => '${m.length} trabajadores',
                          loading: () => 'Cargando...',
                          error: (_, __) => '-',
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: primaryForest)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildGroupInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryForest.withValues(alpha: 0.4)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryForest)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'Administrador';
    final color = isAdmin ? primaryForest : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPaginationFooter(int startIndex, int endIndex, int totalItems, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Text(
            'Mostrando ${totalItems == 0 ? 0 : startIndex + 1} a $endIndex de $totalItems resultados',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
            color: primaryForest,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryForest.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryForest),
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right),
            color: primaryForest,
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(userId: id)));
  }

  void _showCreateGroupDialog() {
    showDialog(context: context, builder: (context) => const GroupFormDialog());
  }

  Future<void> _showEditGroupDialog(Map<String, dynamic> group) async {
    showDialog(context: context, builder: (context) => GroupFormDialog(group: group));
  }

  Future<void> _confirmDeleteGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar Grupo?', style: TextStyle(color: primaryForest, fontWeight: FontWeight.bold)),
        content: const Text('Esta acción eliminará el grupo. Los usuarios no serán eliminados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(usersRepositoryProvider).deleteWorkerGroup(groupId);
    }
  }
}
