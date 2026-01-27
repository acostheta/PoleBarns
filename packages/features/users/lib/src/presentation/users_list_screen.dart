import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/users_repository.dart';
import 'package:design_system/design_system.dart';
import 'dart:async';

enum UsersView { workers, groups }

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  UsersView _currentView = UsersView.workers;
  String? _selectedUserId;
  String? _selectedGroupId;
  bool _isCreatingUser = false;
  String _searchQuery = '';

  // Advanced filters
  bool _showFilters = false;
  String? _filterRole;
  bool? _filterIsActive;
  String? _filterJobPositionId;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final jobPositionsAsync = ref.watch(jobPositionsProvider);

    return usersAsync.when(
      data: (users) {
        // Apply Filters
        final filteredUsers = users.where((u) {
          final name = (u['name'] as String? ?? '').toLowerCase();
          final email = (u['email'] as String? ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();

          final matchesSearch = name.contains(q) || email.contains(q);

          bool matchesRole = true;
          if (_filterRole != null) {
            matchesRole = u['role'] == _filterRole;
          }

          bool matchesStatus = true;
          if (_filterIsActive != null) {
            final isActive = u['is_active'] as bool? ?? false;
            matchesStatus = isActive == _filterIsActive;
          }

          bool matchesPosition = true;
          if (_filterJobPositionId != null) {
            final positionId = u['job_position_id'] as String?;
            matchesPosition = positionId == _filterJobPositionId;
          }

          return matchesSearch &&
              matchesRole &&
              matchesStatus &&
              matchesPosition;
        }).toList();

        final selectedUser = _selectedUserId != null
            ? users.firstWhere(
                (u) => u['id'] == _selectedUserId,
                orElse: () => <String,
                    dynamic>{}, // Return empty map instead of null to match type
              )
            : null;

        // If selectedUser is empty map (not found), treat as null
        final effectiveSelectedUser =
            (selectedUser != null && selectedUser.isNotEmpty)
                ? selectedUser
                : null;

        return Container(
          color: AppColors.backgroundLight,
          child: Column(
            children: [
              // Header Area
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestión de Trabajadores',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Split Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar (List)
                    Container(
                      width: 350,
                      margin: const EdgeInsets.only(left: 24, bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.stone200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // List Header with View Switcher
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Gestión',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.stone100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildViewTab(
                                          'Trabajadores', UsersView.workers),
                                      _buildViewTab('Grupos', UsersView.groups),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _currentView == UsersView.workers
                                        ? _startCreatingUser
                                        : _showCreateGroupDialog,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: Text(
                                        _currentView == UsersView.workers
                                            ? 'Agregar Trabajador'
                                            : 'Crear Nuevo Grupo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_currentView == UsersView.workers) ...[
                            // Search Bar for Users
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.stone100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.search,
                                              color: AppColors.stone400),
                                          hintText: 'Buscar trabajadores...',
                                          hintStyle: TextStyle(
                                              color: AppColors.stone400),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showFilters = !_showFilters;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.filter_list,
                                      color: _showFilters
                                          ? AppColors.primary
                                          : AppColors.stone500,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _showFilters
                                          ? AppColors.primaryLight
                                              .withValues(alpha: 0.2)
                                          : AppColors.stone100,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Advanced Filters Panel
                          if (_showFilters)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.stone50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.stone200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterDropdown(
                                    label: 'Rol',
                                    value: _filterRole,
                                    items: ['Administrador', 'Trabajador'],
                                    onChanged: (val) =>
                                        setState(() => _filterRole = val),
                                    onClear: () =>
                                        setState(() => _filterRole = null),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFilterDropdown(
                                    label: 'Estado',
                                    value: _filterIsActive?.toString(),
                                    itemsMaps: [
                                      {'value': 'true', 'label': 'Activo'},
                                      {'value': 'false', 'label': 'Inactivo'},
                                    ],
                                    onChanged: (val) => setState(
                                        () => _filterIsActive = val == 'true'),
                                    onClear: () =>
                                        setState(() => _filterIsActive = null),
                                  ),
                                  const SizedBox(height: 8),
                                  jobPositionsAsync.when(
                                    data: (positions) => _buildFilterDropdown(
                                      label: 'Puesto',
                                      value: _filterJobPositionId,
                                      itemsMaps: positions
                                          .map<Map<String, String>>((p) => {
                                                'value': p['id'] as String,
                                                'label': p['name'] as String
                                              })
                                          .toList(),
                                      onChanged: (val) => setState(
                                          () => _filterJobPositionId = val),
                                      onClear: () => setState(
                                          () => _filterJobPositionId = null),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),

                          if (_currentView == UsersView.workers) ...[
                            const SizedBox(height: 16),
                            Expanded(
                              child: filteredUsers.isEmpty
                                  ? Center(
                                      child: Text('No se encontraron usuarios',
                                          style: TextStyle(
                                              color: AppColors.stone400)))
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: filteredUsers.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final isSelected = user['id'] ==
                                            (_selectedUserId ?? '');
                                        return _buildUserListItem(
                                            context, user, isSelected);
                                      },
                                    ),
                            ),
                          ] else ...[
                            // Group List Sidebar
                            const SizedBox(height: 16),
                            Expanded(
                              child: ref.watch(workerGroupsProvider).when(
                                    data: (groups) => ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: groups.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final group = groups[index];
                                        final isSelected = group['id'] ==
                                            (_selectedGroupId ?? '');
                                        return _buildGroupListItem(
                                            context, group, isSelected);
                                      },
                                    ),
                                    loading: () => const Center(
                                        child: CircularProgressIndicator()),
                                    error: (e, _) =>
                                        Center(child: Text('Error: $e')),
                                  ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Detail Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _currentView == UsersView.workers
                            ? (_isCreatingUser
                                ? UserCreateFormPanel(
                                    jobPositionsAsync: jobPositionsAsync,
                                    onUserCreated: (newUserId) {
                                      setState(() {
                                        _isCreatingUser = false;
                                        _selectedUserId = newUserId;
                                      });
                                    },
                                    onCancel: () =>
                                        setState(() => _isCreatingUser = false),
                                  )
                                : (effectiveSelectedUser != null
                                    ? UserDetailPanel(
                                        key: ValueKey(effectiveSelectedUser[
                                            'id']), // Add Key to force rebuild on user change
                                        user: effectiveSelectedUser,
                                        jobPositionsAsync: jobPositionsAsync)
                                    : _buildEmptyState('trabajador')))
                            : (_selectedGroupId != null
                                ? GroupDetailPanel(
                                    groupId: _selectedGroupId!,
                                    onGroupDeleted: () =>
                                        setState(() => _selectedGroupId = null),
                                  )
                                : _buildEmptyState('grupo')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    List<String>? items,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.stone500)),
            if (value != null)
              InkWell(
                onTap: onClear,
                child: const Text('Limpiar',
                    style: TextStyle(fontSize: 10, color: AppColors.primary)),
              )
          ],
        ),
        SizedBox(
          height: 36,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.stone300)),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            items: itemsMaps != null
                ? itemsMaps
                    .map((m) => DropdownMenuItem(
                        value: m['value'], child: Text(m['label']!)))
                    .toList()
                : items!
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(
      BuildContext context, Map<String, dynamic> user, bool isSelected) {
    final role = user['role'] as String? ?? 'Sin rol';
    final isActive = user['is_active'] as bool? ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserId = user['id'];
            _isCreatingUser = false;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGreenLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.accentGreen, width: 4))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? user['email'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accentGreenDark
                            : AppColors.textLight,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.accentGreen
                            : AppColors.stone500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : AppColors.stone300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.stone50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stone100),
            ),
            child: const Icon(Icons.person_search,
                size: 64, color: AppColors.stone300),
          ),
          const SizedBox(height: 16),
          Text(
            'Ningún $label seleccionado',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccione un $label de la lista de la izquierda para\nver los detalles de su perfil.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.stone500),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, UsersView view) {
    final isSelected = _currentView == view;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentView = view),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.stone500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startCreatingUser() {
    setState(() {
      _selectedUserId = null;
      _isCreatingUser = true;
    });
  }

  Widget _buildGroupListItem(
      BuildContext context, Map<String, dynamic> group, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGroupId = group['id'];
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGreenLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.accentGreen, width: 4))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: AppColors.stone500),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final usersAsync = ref.watch(allUsersProvider);
                    final supervisorId = group['supervisor_id'] as String?;
                    final supervisorName = usersAsync.when(
                      data: (users) => users.firstWhere(
                        (u) => u['id'] == supervisorId,
                        orElse: () => {},
                      )['name'] as String?,
                      loading: () => '...',
                      error: (_, __) => null,
                    );

                    final displayName = supervisorName != null
                        ? '${group['name']} (Responsable: $supervisorName)'
                        : (group['name'] ?? 'Grupo Sin Nombre');

                    return Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accentGreenDark
                            : AppColors.textLight,
                        fontSize: 15,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Grupo'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Grupo',
            hintText: 'Ej: Equipo A, Cuadrilla de Instalación',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref
                    .read(usersRepositoryProvider)
                    .createWorkerGroup(nameController.text, null);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class UserDetailPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final AsyncValue jobPositionsAsync;

  const UserDetailPanel({
    super.key,
    required this.user,
    required this.jobPositionsAsync,
  });

  @override
  ConsumerState<UserDetailPanel> createState() => _UserDetailPanelState();
}

class _UserDetailPanelState extends ConsumerState<UserDetailPanel> {
  late TextEditingController _nameController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await ref
          .read(usersRepositoryProvider)
          .updateUser(widget.user['id'], {'name': val});
      ref.invalidate(allUsersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final userId = user['id'] as String;
    final isActive = user['is_active'] as bool? ?? false;
    final role = user['role'] as String?;
    final jobPositionId = user['job_position_id'] as String?;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.stone200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.stone200,
                    shape: BoxShape.circle,
                    image: user['picture'] != null
                        ? DecorationImage(
                            image: NetworkImage(user['picture']),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: user['picture'] == null
                      ? Text(
                          (user['name'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stone500),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Desconocido',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.accentGreenLight
                                  : AppColors.stone100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.accentGreenDark
                                    : AppColors.stone500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.stone200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(Icons.badge, 'Información Personal'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre Completo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            onChanged: _onNameChanged,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.stone100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.stone300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.stone300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTextField(
                        label: 'Correo Electrónico',
                        initialValue: user['email'] ?? '',
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name change logic handled in _onNameChanged
                _buildSectionHeader(Icons.admin_panel_settings, 'Rol y Acceso'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Rol del Sistema',
                        value: role,
                        items: ['Administrador', 'Trabajador'],
                        onChanged: (val) async {
                          if (val != null && val != role) {
                            await ref
                                .read(usersRepositoryProvider)
                                .updateUser(userId, {'role': val});
                            ref.invalidate(allUsersProvider);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: widget.jobPositionsAsync.when(
                        data: (positions) => _buildDropdown(
                            label: 'Puesto de Trabajo',
                            value:
                                positions.any((p) => p['id'] == jobPositionId)
                                    ? jobPositionId
                                    : null,
                            itemsMaps: positions
                                .map<Map<String, String>>((p) => {
                                      'value': p['id'] as String,
                                      'label': p['name'] as String
                                    })
                                .toList(),
                            onChanged: (val) async {
                              if (val != null && val != jobPositionId) {
                                await ref
                                    .read(usersRepositoryProvider)
                                    .updateUser(
                                        userId, {'job_position_id': val});
                                ref.invalidate(allUsersProvider);
                              }
                            }),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error al cargar puestos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Estado',
                  value: isActive ? 'true' : 'false',
                  itemsMaps: [
                    {'value': 'true', 'label': 'Activo'},
                    {'value': 'false', 'label': 'Inactivo'}
                  ],
                  onChanged: (val) async {
                    final boolVal = val == 'true';
                    if (boolVal != isActive) {
                      await ref
                          .read(usersRepositoryProvider)
                          .updateUser(userId, {'is_active': boolVal});
                      ref.invalidate(allUsersProvider);
                    }
                  },
                ),

                // Notes Removed Here
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    int maxLines = 1,
    String? hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? AppColors.stone200 : AppColors.stone100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: readOnly ? Colors.transparent : AppColors.stone300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: readOnly ? Colors.transparent : AppColors.stone300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: readOnly ? Colors.transparent : AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    List<String>? items,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.stone100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.stone300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon:
                  const Icon(Icons.arrow_drop_down, color: AppColors.stone500),
              items: itemsMaps != null
                  ? itemsMaps
                      .map((m) => DropdownMenuItem(
                          value: m['value'], child: Text(m['label']!)))
                      .toList()
                  : items!
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class GroupDetailPanel extends ConsumerStatefulWidget {
  final String groupId;
  final VoidCallback onGroupDeleted;

  const GroupDetailPanel({
    super.key,
    required this.groupId,
    required this.onGroupDeleted,
  });

  @override
  ConsumerState<GroupDetailPanel> createState() => _GroupDetailPanelState();
}

class _GroupDetailPanelState extends ConsumerState<GroupDetailPanel> {
  late TextEditingController _nameController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final groups = ref.read(workerGroupsProvider).value;
      if (groups == null) return;
      final group =
          groups.firstWhere((g) => g['id'] == widget.groupId, orElse: () => {});
      if (group.isNotEmpty) {
        await ref
            .read(usersRepositoryProvider)
            .updateWorkerGroup(widget.groupId, val, group['supervisor_id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(workerGroupsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return groupsAsync.when(
      data: (groups) {
        final group = groups.firstWhere((g) => g['id'] == widget.groupId,
            orElse: () => {});
        if (group.isEmpty) return const SizedBox.shrink();

        if (_nameController.text != group['name']) {
          _nameController.text = group['name'] ?? '';
        }

        final supervisorId = group['supervisor_id'] as String?;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Group
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.stone200),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.stone100,
                      child: Icon(Icons.groups,
                          size: 32, color: AppColors.stone500),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            onChanged: _onNameChanged,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight),
                            decoration: const InputDecoration(
                              hintText: 'Nombre del Grupo',
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDeleteGroup(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar Grupo',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Supervisor Assignment
              usersAsync.when(
                data: (users) => _buildSection(
                  title: 'Responsable del Grupo',
                  icon: Icons.person_pin,
                  child: DropdownButtonFormField<String>(
                    value: users.any((u) => u['id'] == supervisorId)
                        ? supervisorId
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.stone100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.stone300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.stone300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      hintText: 'Seleccionar Responsable',
                    ),
                    items: users
                        .map((u) => DropdownMenuItem(
                              value: u['id'] as String,
                              child:
                                  Text(u['name'] ?? u['email'] ?? 'Sin nombre'),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      await ref.read(usersRepositoryProvider).updateWorkerGroup(
                          widget.groupId, group['name'], val);
                    },
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar usuarios'),
              ),
              const SizedBox(height: 24),

              // Members Management
              membersAsync.when(
                data: (members) => _buildSection(
                  title: 'Miembros del Grupo (${members.length})',
                  icon: Icons.group_add,
                  child: Column(
                    children: [
                      _buildAddMemberRow(context, members),
                      const SizedBox(height: 16),
                      if (members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No hay miembros en este grupo',
                              style: TextStyle(color: AppColors.stone400)),
                        )
                      else
                        usersAsync.when(
                          data: (allUsers) => ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final memberId =
                                  members[index]['profile_id'] as String;
                              final user = allUsers.firstWhere(
                                  (u) => u['id'] == memberId,
                                  orElse: () => {});
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.stone100,
                                  backgroundImage: user['picture'] != null
                                      ? NetworkImage(user['picture'])
                                      : null,
                                  child: user['picture'] == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                ),
                                title:
                                    Text(user['name'] ?? 'Usuario Desconocido'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await ref
                                        .read(usersRepositoryProvider)
                                        .removeGroupMember(
                                            widget.groupId, memberId);
                                    ref.invalidate(
                                        groupMembersProvider(widget.groupId));
                                  },
                                ),
                              );
                            },
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSection(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAddMemberRow(
      BuildContext context, List<Map<String, dynamic>> currentMembers) {
    return ref.watch(allUsersProvider).when(
          data: (users) {
            final currentMemberIds =
                currentMembers.map((m) => m['profile_id']).toSet();
            final availableUsers = users
                .where((u) => !currentMemberIds.contains(u['id']))
                .toList();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.stone100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.stone300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.stone300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      hintText: 'Añadir miembro...',
                    ),
                    items: availableUsers
                        .map((u) => DropdownMenuItem(
                              value: u['id'] as String,
                              child:
                                  Text(u['name'] ?? u['email'] ?? 'Sin nombre'),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await ref
                            .read(usersRepositoryProvider)
                            .addGroupMember(widget.groupId, val);
                        ref.invalidate(groupMembersProvider(widget.groupId));
                      }
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Grupo?'),
        content: const Text(
            'Esta acción eliminará el grupo y las asociaciones de sus miembros. No eliminará las cuentas de los trabajadores.'),
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
      await ref.read(usersRepositoryProvider).deleteWorkerGroup(widget.groupId);
      widget.onGroupDeleted();
      ref.invalidate(workerGroupsProvider);
    }
  }
}

class UserCreateFormPanel extends ConsumerStatefulWidget {
  final AsyncValue jobPositionsAsync;
  final Function(String) onUserCreated;
  final VoidCallback onCancel;

  const UserCreateFormPanel({
    super.key,
    required this.jobPositionsAsync,
    required this.onUserCreated,
    required this.onCancel,
  });

  @override
  ConsumerState<UserCreateFormPanel> createState() =>
      _UserCreateFormPanelState();
}

class _UserCreateFormPanelState extends ConsumerState<UserCreateFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Trabajador';
  String? _selectedJobPositionId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newUserId = await ref.read(usersRepositoryProvider).registerWorker(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            role: _selectedRole,
            jobPositionId: _selectedJobPositionId,
          );

      widget.onUserCreated(newUserId);
      ref.invalidate(allUsersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajador creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear trabajador: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevo Trabajador',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.person_add, 'Información del Perfil'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                hint: 'Ej: Juan Pérez',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                hint: 'correo@ejemplo.com',
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (!val.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña Temporal',
                hint: 'Mínimo 6 caracteres',
                obscureText: true,
                validator: (val) =>
                    val == null || val.length < 6 ? 'Mínimo 6 chars' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                  Icons.admin_panel_settings, 'Configuración de Acceso'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Rol en el Sistema',
                      value: _selectedRole,
                      items: ['Administrador', 'Trabajador'],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: widget.jobPositionsAsync.when(
                      data: (positions) => _buildDropdown(
                        label: 'Puesto de Trabajo',
                        value: _selectedJobPositionId,
                        itemsMaps: positions
                            .map<Map<String, String>>((p) => {
                                  'value': p['id'] as String,
                                  'label': p['name'] as String
                                })
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedJobPositionId = val),
                      ),
                      loading: () =>
                          const Center(child: LinearProgressIndicator()),
                      error: (_, __) => const Text('Error al cargar puestos'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Crear Trabajador',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.stone100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    List<String>? items,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.stone100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: itemsMaps != null
              ? itemsMaps
                  .map((m) => DropdownMenuItem(
                      value: m['value'], child: Text(m['label']!)))
                  .toList()
              : items!
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
