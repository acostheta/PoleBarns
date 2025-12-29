import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';

class CostsTab extends ConsumerWidget {
  final String projectId;

  const CostsTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costsAsync = ref.watch(projectCostsProvider(projectId));
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      body: costsAsync.when(
        data: (costs) {
          if (costs.isEmpty) {
            return const Center(child: Text('No hay costos registrados.'));
          }
          return ListView.builder(
            itemCount: costs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final cost = costs[index];
              return Card(
                key: ValueKey(cost.id),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: Text(cost.concepto),
                  subtitle: cost.notas != null && cost.notas!.isNotEmpty
                      ? Text(cost.notas!)
                      : null,
                  trailing: Text(
                    currency.format(cost.monto),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCostDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCostDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddCostDialog(projectId: projectId),
    );
  }
}

class _AddCostDialog extends ConsumerStatefulWidget {
  final String projectId;

  const _AddCostDialog({required this.projectId});

  @override
  ConsumerState<_AddCostDialog> createState() => _AddCostDialogState();
}

class _AddCostDialogState extends ConsumerState<_AddCostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.addCost(
        widget.projectId,
        _conceptController.text,
        amount,
        _notesController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Costo agregado exitosamente')),
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
    return AlertDialog(
      title: const Text('Agregar Costo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _conceptController,
              decoration: const InputDecoration(labelText: 'Concepto'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Inválido';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas (Opcional)'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator())
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
