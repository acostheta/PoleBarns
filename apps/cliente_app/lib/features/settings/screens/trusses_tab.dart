import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/settings_repository.dart';
import '../models/truss_model.dart';
import '../../../config/ui_helpers.dart';
import '../../../config/app_styles.dart';

class TrussesTab extends ConsumerWidget {
  const TrussesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trussesAsync = ref.watch(trussesListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTrussDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: trussesAsync.when(
        data: (trusses) {
          if (trusses.isEmpty) {
            return const Center(
                child: Text('No hay productos registrados en el catálogo.'));
          }
          return ListView.builder(
            itemCount: trusses.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final truss = trusses[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build_circle_outlined,
                      color: Colors.deepOrange),
                  title: Text(truss.name),
                  subtitle: Text(
                    'Costo: ${NumberFormat.simpleCurrency().format(truss.cost)}',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showTrussDialog(context, ref, truss: truss),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await AppBottomSheet.showConfirm(
                            context: context,
                            title: 'Confirmar',
                            message: '¿Estás seguro de eliminar este producto del catálogo?',
                            confirmLabel: 'Eliminar',
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            try {
                              await ref
                                  .read(settingsRepositoryProvider)
                                  .deleteTruss(truss.id);
                              ref.invalidate(trussesListProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error al eliminar: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showTrussDialog(BuildContext context, WidgetRef ref, {Truss? truss}) {
    final nameController = TextEditingController(text: truss?.name ?? '');
    final costController =
        TextEditingController(text: truss?.cost.toString() ?? '');
    final isEditing = truss != null;

    AppBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Editar Producto' : 'Nuevo Producto',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Nombre del Producto', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: AppStyles.inputDecoration(),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Costo Unitario', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: costController,
              decoration: AppStyles.inputDecoration().copyWith(
                prefixText: '\$ ',
                helperText: 'Costo por unidad del producto',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: AppStyles.primaryButtonStyle,
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nombre es requerido')),
                    );
                    return;
                  }

                  final cost = double.tryParse(costController.text) ?? 0.0;

                  try {
                    if (truss != null) {
                      final updated = Truss(
                        id: truss.id,
                        name: nameController.text,
                        cost: cost,
                        createdAt: truss.createdAt,
                      );
                      await ref
                          .read(settingsRepositoryProvider)
                          .updateTruss(updated);
                    } else {
                      await ref
                          .read(settingsRepositoryProvider)
                          .createTruss(nameController.text, cost);
                    }
                    ref.invalidate(trussesListProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar: $e')),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
