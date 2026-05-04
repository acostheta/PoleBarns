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

  // Branded Colors
  static const Color primaryForest = Color(0xFF173124);
  static const Color secondaryEarth = Color(0xFF7C580F);
  static const Color backgroundLight = Color(0xFFFDFBF7);

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

    try {
      final members = await ref.read(usersRepositoryProvider).getGroupMembers(widget.group!['id']).first;
      if (mounted) {
        setState(() {
          _selectedMemberIds.addAll(members.map((m) => m['profile_id'] as String));
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
        const SnackBar(content: Text('Debe seleccionar un responsable'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(usersRepositoryProvider);
    final name = _nameController.text.trim();

    try {
      String groupId;

      if (widget.group == null) {
        groupId = await repo.createWorkerGroup(name, _selectedSupervisorId);
        final membersToAdd = {..._selectedMemberIds, _selectedSupervisorId!};
        for (final uid in membersToAdd) {
          await repo.addGroupMember(groupId, uid);
        }
      } else {
        groupId = widget.group!['id'];
        await repo.updateWorkerGroup(groupId, name, _selectedSupervisorId);
        final currentMembers = await repo.getGroupMembers(groupId).first;
        final currentMemberIds = currentMembers.map((m) => m['profile_id'] as String).toSet();
        final newMemberIds = {..._selectedMemberIds, _selectedSupervisorId!};

        for (final uid in newMemberIds) {
          if (!currentMemberIds.contains(uid)) {
            await repo.addGroupMember(groupId, uid);
          }
        }
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
            content: Text(widget.group == null ? 'Grupo creado exitosamente' : 'Grupo actualizado exitosamente'),
            backgroundColor: primaryForest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branded Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: primaryForest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.group_add_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    widget.group == null ? 'Nuevo Grupo' : 'Editar Grupo',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre del Grupo',
                        hint: 'Ej: Equipo de Construcción Alpha',
                        icon: Icons.title_outlined,
                        validator: (v) => v == null || v.isEmpty ? 'El nombre es requerido' : null,
                      ),
                      const SizedBox(height: 24),

                      usersAsync.when(
                        data: (users) {
                          final activeUsers = users.where((u) => u['is_active'] == true).toList();
                          return _buildDropdown(
                            label: 'Responsable (Líder)',
                            value: activeUsers.any((u) => u['id'] == _selectedSupervisorId) ? _selectedSupervisorId : null,
                            icon: Icons.star_border_rounded,
                            itemsMaps: activeUsers.map((u) => {'value': u['id'] as String, 'label': u['name'] ?? 'Sin nombre'}).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSupervisorId = val;
                                if (val != null) _selectedMemberIds.add(val);
                              });
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(color: primaryForest),
                        error: (_, __) => const Text('Error cargando usuarios', style: TextStyle(color: Colors.red)),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Miembros Seleccionados'),
                      const SizedBox(height: 12),
                      _buildMemberChips(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Seleccionar Personal'),
                      const SizedBox(height: 12),
                      _buildMembersSelectionList(usersAsync),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundLight,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryForest.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryForest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(widget.group == null ? 'CREAR GRUPO' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: secondaryEarth, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: primaryForest.withValues(alpha: 0.6), letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildMemberChips() {
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    if (_selectedMemberIds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.05), style: BorderStyle.solid)),
        child: Text('Ningún miembro seleccionado', style: TextStyle(fontSize: 13, color: primaryForest.withValues(alpha: 0.4), fontStyle: FontStyle.italic)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedMemberIds.map((id) {
        final user = users.firstWhere((u) => u['id'] == id, orElse: () => {'name': 'Desconocido'});
        final isSupervisor = id == _selectedSupervisorId;
        return Chip(
          backgroundColor: isSupervisor ? secondaryEarth.withValues(alpha: 0.1) : Colors.white,
          side: BorderSide(color: isSupervisor ? secondaryEarth.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),
          avatar: CircleAvatar(
            backgroundColor: isSupervisor ? secondaryEarth : primaryForest.withValues(alpha: 0.1),
            child: Text((user['name'] as String? ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 10, color: isSupervisor ? Colors.white : primaryForest, fontWeight: FontWeight.bold)),
          ),
          label: Text('${user['name']}${isSupervisor ? ' (Líder)' : ''}', style: TextStyle(fontSize: 12, fontWeight: isSupervisor ? FontWeight.bold : FontWeight.normal, color: primaryForest)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: isSupervisor ? null : () => setState(() => _selectedMemberIds.remove(id)),
        );
      }).toList(),
    );
  }

  Widget _buildMembersSelectionList(AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    return usersAsync.when(
      data: (users) {
        final activeUsers = users.where((u) => u['is_active'] == true).toList();
        if (activeUsers.isEmpty) return const Text('No hay usuarios activos disponibles.');

        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              itemCount: activeUsers.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final user = activeUsers[index];
                final uid = user['id'] as String;
                final isSelected = _selectedMemberIds.contains(uid);
                final isSupervisor = uid == _selectedSupervisorId;

                return CheckboxListTile(
                  title: Text(user['name'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryForest)),
                  subtitle: Text(user['email'] ?? '-', style: TextStyle(fontSize: 12, color: primaryForest.withValues(alpha: 0.5))),
                  value: isSelected,
                  activeColor: primaryForest,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: isSupervisor ? null : (val) {
                    setState(() {
                      if (val == true) _selectedMemberIds.add(uid);
                      else _selectedMemberIds.remove(uid);
                    });
                  },
                  secondary: isSupervisor ? const Icon(Icons.star, color: secondaryEarth, size: 20) : null,
                );
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: primaryForest)),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryForest.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: primaryForest.withValues(alpha: 0.4), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: secondaryEarth, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required List<Map<String, String>> itemsMaps,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryForest.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: (v) => v == null ? 'Seleccione un responsable' : null,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: primaryForest),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryForest.withValues(alpha: 0.4), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: secondaryEarth, width: 2)),
          ),
          items: itemsMaps.map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!))).toList(),
        ),
      ],
    );
  }
}
