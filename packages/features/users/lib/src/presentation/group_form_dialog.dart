import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';

class GroupFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? group; // If null, creating new

  const GroupFormDialog({super.key, this.group});

  @override
  ConsumerState<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  // Selection State
  final Set<String> _selectedMemberIds = {};
  String? _selectedSupervisorId;

  bool _isLoading = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?['name'] ?? '');
    _selectedSupervisorId = widget.group?['supervisor_id'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load existing members if editing
  Future<void> _loadMembers() async {
    if (widget.group == null) return;

    // We fetch current members to populate the selection
    try {
      final members = await ref
          .read(usersRepositoryProvider)
          .getGroupMembers(widget.group!['id'])
          .first;
      if (mounted) {
        setState(() {
          _selectedMemberIds
              .addAll(members.map((m) => m['profile_id'] as String));
          // If supervisor is not in members (should act be?), add them?
          // Typically supervisor IS a member too, but let's ensure consistency if needed.
        });
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && widget.group != null) {
      _loadMembers();
      _isInit = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un responsable')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(usersRepositoryProvider);
    final name = _nameController.text.trim();

    try {
      String groupId;

      // 1. Create or Update Group
      if (widget.group == null) {
        // Create
        groupId = await repo.createWorkerGroup(name, _selectedSupervisorId);

        // Add all selected members
        // Also ensure supervisor is a member? Usually yes.
        final membersToAdd = {..._selectedMemberIds, _selectedSupervisorId!};

        for (final uid in membersToAdd) {
          await repo.addGroupMember(groupId, uid);
        }
      } else {
        // Update
        groupId = widget.group!['id'];
        await repo.updateWorkerGroup(groupId, name, _selectedSupervisorId);

        // Sync members
        // Fetch current to compare or just delete all and re-add? Delete all is destructive if there's metadata.
        // Table worker_group_members only has id, group_id, profile_id. So delete/add is safe enough?
        // But let's try to be smart: find toAdd and toRemove.

        final currentMembers = await repo.getGroupMembers(groupId).first;
        final currentMemberIds =
            currentMembers.map((m) => m['profile_id'] as String).toSet();

        final newMemberIds = {..._selectedMemberIds, _selectedSupervisorId!};

        // To Add
        for (final uid in newMemberIds) {
          if (!currentMemberIds.contains(uid)) {
            await repo.addGroupMember(groupId, uid);
          }
        }

        // To Remove
        for (final uid in currentMemberIds) {
          if (!newMemberIds.contains(uid)) {
            await repo.removeGroupMember(groupId, uid);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  widget.group == null ? 'Grupo creado' : 'Grupo actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return AlertDialog(
      title: Text(widget.group == null ? 'Nuevo Grupo' : 'Editar Grupo'),
      content: SizedBox(
        // Limit size
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Grupo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // Supervisor Dropdown
                // Needs list of users.
                usersAsync.when(
                    data: (users) {
                      // Filter only active users? Probably.
                      final activeUsers =
                          users.where((u) => u['is_active'] == true).toList();

                      return DropdownButtonFormField<String>(
                        value: activeUsers
                                .any((u) => u['id'] == _selectedSupervisorId)
                            ? _selectedSupervisorId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Responsable (Supervisor) *',
                          border: OutlineInputBorder(),
                        ),
                        items: activeUsers
                            .map((u) => DropdownMenuItem(
                                  value: u['id'] as String,
                                  child: Text(u['name'] ?? 'Sin nombre'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSupervisorId = val;
                            // Auto-add supervisor to members if not present?
                            if (val != null) {
                              _selectedMemberIds.add(val);
                            }
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Seleccione un responsable' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error cargando usuarios')),

                const SizedBox(height: 24),

                // Selected Members Summary
                if (_selectedMemberIds.isNotEmpty) ...[
                  const Text('Miembros del Grupo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final users = usersAsync.valueOrNull ?? [];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.stone50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.stone200),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMemberIds.map((id) {
                          final user = users.firstWhere(
                            (u) => u['id'] == id,
                            orElse: () => {'name': 'Desconocido'},
                          );
                          final isSupervisor = id == _selectedSupervisorId;
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: isSupervisor
                                  ? Colors.orange
                                  : AppColors.primary,
                              child: Text(
                                (user['name'] as String? ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                            label: Text(
                              '${user['name']}${isSupervisor ? ' (Líder)' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.stone300),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: isSupervisor
                                ? null
                                : () => setState(
                                    () => _selectedMemberIds.remove(id)),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                const Text('Seleccionar:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Members List with Checkboxes
                usersAsync.when(
                  data: (users) {
                    final activeUsers =
                        users.where((u) => u['is_active'] == true).toList();
                    if (activeUsers.isEmpty)
                      return const Text('No hay usuarios activos.');

                    return Container(
                      height: 200, // Fixed height for list
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.stone300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: activeUsers.length,
                        itemBuilder: (context, index) {
                          final user = activeUsers[index];
                          final uid = user['id'] as String;
                          final isSelected = _selectedMemberIds.contains(uid);
                          final isSupervisor = uid == _selectedSupervisorId;

                          return CheckboxListTile(
                            title: Text(user['name'] ?? '-'),
                            subtitle: Text(user['email'] ?? '-'),
                            value: isSelected,
                            onChanged: isSupervisor
                                ? null
                                : (val) {
                                    // Supervisor cannot be unchecked unless changed in dropdown
                                    setState(() {
                                      if (val == true) {
                                        _selectedMemberIds.add(uid);
                                      } else {
                                        _selectedMemberIds.remove(uid);
                                      }
                                    });
                                  },
                            secondary: isSupervisor
                                ? const Icon(Icons.star, color: Colors.orange)
                                : null,
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(widget.group == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
