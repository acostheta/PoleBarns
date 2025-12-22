import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/users_repository.dart';
import 'package:design_system/design_system.dart';
import 'dart:async';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  String? _selectedUserId;
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
                      'Gestión de Usuarios',
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
                          // List Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Lista de Usuarios',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  '${filteredUsers.length} Encontrados',
                                  style: const TextStyle(
                                    color: AppColors.stone500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        hintText: 'Buscar usuarios...',
                                        hintStyle: TextStyle(
                                            color: AppColors.stone400),
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 14),
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
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),

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

                          const SizedBox(height: 16),
                          // User List Items
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
                                      final isSelected =
                                          user['id'] == (_selectedUserId ?? '');
                                      return _buildUserListItem(
                                          context, user, isSelected);
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Detail Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: effectiveSelectedUser != null
                            ? UserDetailPanel(
                                key: ValueKey(effectiveSelectedUser[
                                    'id']), // Add Key to force rebuild on user change
                                user: effectiveSelectedUser,
                                jobPositionsAsync: jobPositionsAsync)
                            : _buildEmptyState(),
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

  Widget _buildEmptyState() {
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
          const Text(
            'Ningún usuario seleccionado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un usuario de la lista de la izquierda para\nver los detalles de su perfil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.stone500),
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
