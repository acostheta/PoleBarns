import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';
import '../models/payment_method_model.dart';

class PaymentMethodsTab extends ConsumerWidget {
  const PaymentMethodsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMethodDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return const Center(
                child: Text('No hay métodos de pago registrados.'));
          }
          return ListView.builder(
            itemCount: methods.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final method = methods[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payment),
                  title: Text(method.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showMethodDialog(context, ref, method: method),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar'),
                              content: const Text(
                                  '¿Estás seguro de eliminar este método de pago?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(settingsRepositoryProvider)
                                .deletePaymentMethod(method.id);
                            ref.invalidate(paymentMethodsListProvider);
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

  void _showMethodDialog(BuildContext context, WidgetRef ref,
      {PaymentMethodModel? method}) {
    final nameController = TextEditingController(text: method?.name ?? '');
    final isEditing = method != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(isEditing ? 'Editar Método de Pago' : 'Nuevo Método de Pago'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
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

              try {
                if (method != null) {
                  final updated = method.copyWith(
                    name: nameController.text,
                  );
                  await ref
                      .read(settingsRepositoryProvider)
                      .updatePaymentMethod(updated);
                } else {
                  await ref
                      .read(settingsRepositoryProvider)
                      .createPaymentMethod(
                        nameController.text,
                      );
                }
                ref.invalidate(paymentMethodsListProvider);
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
