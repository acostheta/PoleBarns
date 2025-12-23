import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../settings/models/payment_method_model.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';

class RegisterPaymentDialog extends ConsumerStatefulWidget {
  final AccountPayableModel account;

  const RegisterPaymentDialog({super.key, required this.account});

  @override
  ConsumerState<RegisterPaymentDialog> createState() =>
      _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends ConsumerState<RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMethodId;
  DateTime _paymentDate = DateTime.now();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMethodId == null) {
        return; // Validator handles msg
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      // Additional safety check
      if (amount > widget.account.currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El monto no puede exceder el saldo pendiente')),
        );
        return;
      }

      Navigator.of(context).pop();

      try {
        final repo = ref.read(accountsPayableRepositoryProvider);
        await repo.addPayment(
          apId: widget.account.id,
          date: _paymentDate,
          amount: amount,
          paymentMethodId: _selectedMethodId,
          notes: _notesController.text,
        );

        // Refresh the main list to update balances
        ref.read(accountsPayableListProvider.notifier).loadAccounts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abonar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return AlertDialog(
      title: Text(
          'Abonar a Factura: ${widget.account.invoiceInternRef ?? "Sin Ref"}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Saldo Pendiente: \$${widget.account.currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 16),

              // Payment Method
              methodsAsync.when(
                data: (methods) => DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Método de Pago'),
                  value: _selectedMethodId,
                  items: methods.map((PaymentMethodModel m) {
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMethodId = val),
                  validator: (val) => val == null ? 'Requerido' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error loading methods: $e'),
              ),
              const SizedBox(height: 16),

              // Date
              InputDatePickerFormField(
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDate: _paymentDate,
                onDateSubmitted: (date) => _paymentDate = date,
                onDateSaved: (date) => _paymentDate = date,
              ),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a Abonar',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Inválido';
                  if (n > widget.account.currentBalance) {
                    return 'Excede el saldo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notas (Opcional)'),
                maxLines: 2,
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
          child: const Text('Abonar'),
        ),
      ],
    );
  }
}
