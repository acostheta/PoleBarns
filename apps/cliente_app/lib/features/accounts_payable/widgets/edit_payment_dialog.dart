import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/ap_payment_model.dart';
import '../providers/accounts_payable_provider.dart';
import '../../settings/repositories/settings_repository.dart';

class EditPaymentDialog extends ConsumerStatefulWidget {
  final APPaymentModel payment;

  const EditPaymentDialog({super.key, required this.payment});

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String? _selectedMethodId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.payment.amount.toString());
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    _selectedDate = widget.payment.date;
    _selectedMethodId = widget.payment.paymentMethodId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Editar Pago', style: AppStyles.dialogTitleStyle),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date
            const Text('Fecha de Pago', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Amount
            const Text('Monto', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: AppStyles.inputDecoration()
                  .copyWith(prefixText: r'$ ', hintText: '0.00'),
            ),

            const SizedBox(height: 20),

            // Payment Method
            const Text('Método de Pago', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            methodsAsync.when(
              data: (methods) => DropdownButtonFormField<String>(
                value: _selectedMethodId,
                decoration: AppStyles.inputDecoration(),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: methods
                    .map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMethodId = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 20),

            // Notes
            const Text('Notas (Opcional)', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: AppStyles.inputDecoration()
                  .copyWith(hintText: 'Agregar notas...'),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: AppStyles.primaryButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(accountsPayableRepositoryProvider).updatePayment(
            paymentId: widget.payment.id,
            date: _selectedDate,
            amount: amount,
            paymentMethodId: _selectedMethodId,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

      ref.invalidate(accountPaymentsProvider(widget.payment.apId));
      ref.invalidate(accountPayableDetailProvider(widget.payment.apId));
      ref.invalidate(accountsPayableListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
