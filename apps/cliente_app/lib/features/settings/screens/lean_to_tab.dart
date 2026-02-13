import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/settings_repository.dart';
import '../models/lean_to_model.dart';

class LeanToTab extends ConsumerWidget {
  const LeanToTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leanTosAsync = ref.watch(leanTosListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLeanToDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: leanTosAsync.when(
        data: (leanTos) {
          if (leanTos.isEmpty) {
            return const Center(
                child: Text(
                    'No hay productos Lean Too registrados en el catálogo.'));
          }
          return ListView.builder(
            itemCount: leanTos.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final leanTo = leanTos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.roofing, color: Colors.deepOrange),
                  title: Text(leanTo.name),
                  subtitle: Text(
                    'Costo: ${NumberFormat.simpleCurrency().format(leanTo.cost)}',
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
                            _showLeanToDialog(context, ref, leanTo: leanTo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar'),
                              content: const Text(
                                  '¿Estás seguro de eliminar este producto Lean Too del catálogo?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref
                                  .read(settingsRepositoryProvider)
                                  .deleteLeanTo(leanTo.id);
                              ref.invalidate(leanTosListProvider);
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

  void _showLeanToDialog(BuildContext context, WidgetRef ref,
      {LeanTo? leanTo}) {
    final nameController = TextEditingController(text: leanTo?.name ?? '');
    final costController =
        TextEditingController(text: leanTo?.cost.toString() ?? '');
    final isEditing = leanTo != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            isEditing ? 'Editar Producto Lean Too' : 'Nuevo Producto Lean Too'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Producto'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Costo Unitario',
                prefixText: '\$ ',
                helperText: 'Costo por unidad del producto',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre es requerido')),
                );
                return;
              }

              final cost = double.tryParse(costController.text) ?? 0.0;

              try {
                if (leanTo != null) {
                  final updated = LeanTo(
                    id: leanTo.id,
                    name: nameController.text,
                    cost: cost,
                    createdAt: leanTo.createdAt,
                  );
                  await ref
                      .read(settingsRepositoryProvider)
                      .updateLeanTo(updated);
                } else {
                  await ref
                      .read(settingsRepositoryProvider)
                      .createLeanTo(nameController.text, cost);
                }
                ref.invalidate(leanTosListProvider);
                if (context.mounted) Navigator.pop(ctx);
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
        ],
      ),
    );
  }
}
