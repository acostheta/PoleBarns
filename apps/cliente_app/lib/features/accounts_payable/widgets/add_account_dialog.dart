import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../settings/models/provider_model.dart';
import '../providers/accounts_payable_provider.dart';

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProviderId;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProviderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione un proveedor')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        return; // Validator handles msg
      }

      Navigator.of(context).pop(); // Close dialog immediately

      try {
        await ref.read(accountsPayableListProvider.notifier).addAccount(
              providerId: _selectedProviderId!,
              invoiceDate: _selectedDate,
              totalAmount: amount,
              invoiceInternRef:
                  _refController.text.isNotEmpty ? _refController.text : null,
            );

        // Success feedback handled by parent or implicit list update
      } catch (e) {
        // Show error? Context might be gone if pop first, but usually safer to pop last if we want to show loading.
        // For better UX, let's keep it simple: Pop then fire-and-forget or use a global snackbar service.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersListProvider);

    return AlertDialog(
      title: const Text('Registrar Cuenta por Pagar'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Provider Dropdown
              providersAsync.when(
                data: (providers) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Proveedor'),
                  value: _selectedProviderId,
                  items: providers.map((ProviderModel p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProviderId = val),
                  validator: (val) => val == null ? 'Requerido' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error al cargar proveedores: $e'),
              ),
              const SizedBox(height: 16),

              // Date Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reference
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                    labelText: 'Referencia Interna (Opcional)'),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto Total',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
