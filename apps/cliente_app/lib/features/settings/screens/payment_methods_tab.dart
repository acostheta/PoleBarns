import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';
import '../models/payment_method_model.dart';
import '../../../config/ui_helpers.dart';
import '../../../config/app_styles.dart';

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
                  subtitle: method.serviceFee > 0
                      ? Text('Service Fee: ${method.serviceFee}%',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500))
                      : null,
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
                          final confirm = await AppBottomSheet.showConfirm(
                            context: context,
                            title: 'Confirmar',
                            message: '¿Estás seguro de eliminar este método de pago?',
                            confirmLabel: 'Eliminar',
                            isDestructive: true,
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
    final feeController =
        TextEditingController(text: method?.serviceFee.toString() ?? '0.0');
    final isEditing = method != null;

    AppBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Editar Método de Pago' : 'Nuevo Método de Pago',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Nombre', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: AppStyles.inputDecoration(),
            ),
            const SizedBox(height: 16),
            const Text('Service Fee (%)', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: feeController,
              decoration: AppStyles.inputDecoration().copyWith(
                helperText: 'Cargo adicional porcentual (ej. 3.5)',
              ),
              keyboardType: TextInputType.number,
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

                  final fee = double.tryParse(feeController.text) ?? 0.0;

                  try {
                    if (method != null) {
                      final updated = method.copyWith(
                        name: nameController.text,
                        serviceFee: fee,
                      );
                      await ref
                          .read(settingsRepositoryProvider)
                          .updatePaymentMethod(updated);
                    } else {
                      await ref
                          .read(settingsRepositoryProvider)
                          .createPaymentMethod(
                            nameController.text,
                            serviceFee: fee,
                          );
                    }
                    ref.invalidate(paymentMethodsListProvider);
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
