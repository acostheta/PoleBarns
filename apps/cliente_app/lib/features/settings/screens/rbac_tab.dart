import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/rbac_repository.dart';
import '../models/rbac_model.dart';
import '../../../config/ui_helpers.dart';

class RbacTab extends ConsumerStatefulWidget {
  const RbacTab({super.key});

  @override
  ConsumerState<RbacTab> createState() => _RbacTabState();
}

class _RbacTabState extends ConsumerState<RbacTab> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesListProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Roles y Permisos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRoleDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Rol'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Role Selector with Edit/Delete actions
          rolesAsync.when(
            data: (roles) {
              if (roles.isEmpty) {
                return const Text('No hay roles definidos. Cree uno nuevo.');
              }

              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Rol de Usuario',
                        border: OutlineInputBorder(),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role['name'],
                          child: Text(role['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),
                  if (_selectedRole != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        final role =
                            roles.firstWhere((r) => r['name'] == _selectedRole);
                        _showRoleDialog(context, role: role);
                      },
                      tooltip: 'Editar nombre del rol',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        final role =
                            roles.firstWhere((r) => r['name'] == _selectedRole);
                        _confirmDeleteRole(context, role);
                      },
                      tooltip: 'Eliminar rol',
                    ),
                  ]
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => Text('Error al cargar roles: $err'),
          ),
          const SizedBox(height: 24),

          // Modules List
          if (_selectedRole != null)
            Expanded(
              child: _ModulesList(roleName: _selectedRole!),
            )
          else
            const Expanded(
                child: Center(
                    child: Text('Seleccione un rol para ver sus permisos.'))),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, {Map<String, dynamic>? role}) {
    final nameController = TextEditingController(text: role?['name']);
    final isEditing = role != null;

    AppBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Rol' : 'Nuevo Rol',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF173124)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Rol',
                hintText: 'Ej: Supervisor, Vendedor...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173124),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;

                  try {
                    final repo = ref.read(rbacRepositoryProvider);
                    if (isEditing) {
                      await repo.updateRole(role['id'], role['name'], newName);
                    } else {
                      await repo.createRole(newName);
                    }

                    ref.invalidate(rolesListProvider);
                    if (isEditing) {
                      setState(() {
                        _selectedRole = newName;
                      });
                    }

                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Actualizar Rol' : 'Crear Rol'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRole(BuildContext context, Map<String, dynamic> role) async {
    if (role['name'] == 'Administrador') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se puede eliminar el rol Administrador.')),
      );
      return;
    }

    final confirmed = await AppBottomSheet.showConfirm(
      context: context,
      title: 'Eliminar Rol',
      message: '¿Está seguro de eliminar el rol "${role['name']}"? Se perderán todos sus permisos asociados.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await ref
            .read(rbacRepositoryProvider)
            .deleteRole(role['id'], role['name']);
        ref.invalidate(rolesListProvider);
        setState(() {
          _selectedRole = null;
        });
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}

class _ModulesList extends ConsumerWidget {
  final String roleName;

  const _ModulesList({required this.roleName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesListProvider);
    final permissionsAsync = ref.watch(rolePermissionsProvider(roleName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permisos por Módulo:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: modulesAsync.when(
            data: (modules) {
              return permissionsAsync.when(
                data: (permissions) {
                  return ListView.separated(
                    itemCount: modules.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      final perm = permissions.firstWhere(
                        (p) => p.moduleId == module.id,
                        orElse: () => RolePermission(
                          id: '',
                          roleName: roleName,
                          moduleId: module.id,
                          canAccess: false,
                        ),
                      );

                      return SwitchListTile(
                        title: Text(module.name),
                        subtitle: Text('Clave: ${module.key}'),
                        value: perm.canAccess && perm.id.isNotEmpty,
                        onChanged: (bool value) async {
                          try {
                            await ref
                                .read(rbacRepositoryProvider)
                                .updatePermission(
                                  roleName,
                                  module.id,
                                  value,
                                );
                            ref.invalidate(rolePermissionsProvider(roleName));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error al actualizar permiso: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text('Error al cargar permisos: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error al cargar módulos: $e')),
          ),
        ),
      ],
    );
  }
}
