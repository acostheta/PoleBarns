import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';

class JobPositionsScreen extends ConsumerStatefulWidget {
  const JobPositionsScreen({super.key});

  @override
  ConsumerState<JobPositionsScreen> createState() => _JobPositionsScreenState();
}

class _JobPositionsScreenState extends ConsumerState<JobPositionsScreen> {
  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(jobPositionsProvider);

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
                  'Puestos de Trabajo',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPositionDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Agregar Puesto'),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: positionsAsync.when(
                data: (positions) {
                  if (positions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: AppColors.stone300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No se encontraron puestos de trabajo',
                            style: TextStyle(
                              color: AppColors.stone500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.stone200),
                    ),
                    color: AppColors.surfaceLight,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: positions.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppColors.stone200,
                      ),
                      itemBuilder: (context, index) {
                        final pos = positions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          title: Text(
                            pos['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: AppColors.stone500,
                                ),
                                onPressed: () => _showPositionDialog(
                                  context,
                                  position: pos,
                                ),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _confirmDelete(context, pos),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPositionDialog(
    BuildContext context, {
    Map<String, dynamic>? position,
  }) {
    final isEditing = position != null;
    final controller = TextEditingController(
      text: isEditing ? position['name'] : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Puesto' : 'Nuevo Puesto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Puesto',
                  hintText: 'ej. Desarrollador, Gerente',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.stone500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final name = controller.text.trim();
                  if (isEditing) {
                    await ref
                        .read(usersRepositoryProvider)
                        .updateJobPosition(position['id'], name);
                  } else {
                    await ref
                        .read(usersRepositoryProvider)
                        .createJobPosition(name);
                  }
                  ref.invalidate(jobPositionsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Puesto'),
        content: Text(
          '¿Está seguro de que desea eliminar "${position['name']}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.stone500),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(usersRepositoryProvider)
                    .deleteJobPosition(position['id']);
                ref.invalidate(jobPositionsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted)
                  Navigator.pop(context); // Close the confirmation dialog

                final errString = e.toString().toLowerCase();
                if (errString.contains('violates foreign key constraint') ||
                    errString.contains('foreign key constraint') ||
                    errString.contains('23503')) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'No se puede eliminar el puesto',
                      ),
                      content: const Text(
                        'Este puesto de trabajo está asignado actualmente a uno o más usuarios. Por favor, reasigne a esos usuarios antes de eliminar este puesto.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
