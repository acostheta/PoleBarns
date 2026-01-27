import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../settings/models/payment_method_model.dart';

class EditPaymentDialog extends ConsumerStatefulWidget {
  final InvoicePaymentModel payment;
  final double maxAmount;
  final VoidCallback onUpdated;

  const EditPaymentDialog({
    super.key,
    required this.payment,
    required this.maxAmount,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _tipo;
  late String? _selectedMethodId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.payment.amount.toString());
    _noteController = TextEditingController(text: widget.payment.nota ?? '');
    _tipo = widget.payment.tipo;
    _selectedMethodId = widget.payment.paymentMethodId?.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Tipo de Transacción', style: AppStyles.labelStyle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                      'Abono', Icons.add_circle_outline, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                      'Reembolso', Icons.remove_circle_outline, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Método de Pago', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            ref.watch(paymentMethodsListProvider).when(
                  data: (methods) {
                    return DropdownButtonFormField<String>(
                      value: _selectedMethodId,
                      decoration: AppStyles.inputDecoration(),
                      items: methods
                          .map<DropdownMenuItem<String>>(
                              (PaymentMethodModel m) =>
                                  DropdownMenuItem<String>(
                                      value: m.id.toString(),
                                      child: Text(m.name)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedMethodId = val),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
            const SizedBox(height: 24),
            const Text('Monto', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: AppStyles.inputDecoration()
                  .copyWith(prefixText: r'$ ', hintText: '0.00'),
            ),
            const SizedBox(height: 24),
            const Text('Notas (Opcional)', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: AppStyles.inputDecoration()
                  .copyWith(hintText: 'Agregar notas...'),
            ),
            const SizedBox(height: 32),
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

  Widget _buildTypeButton(String label, IconData icon, Color color) {
    final isSelected = _tipo == label;
    return InkWell(
      onTap: () => setState(() => _tipo = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border:
              Border.all(color: isSelected ? color : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
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

    if (_selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un método de pago')),
      );
      return;
    }

    if (amount > widget.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'El monto no puede exceder el total del proyecto (\$${widget.maxAmount.toStringAsFixed(2)})'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'amount': amount,
        'tipo': _tipo,
        'nota': _noteController.text.isEmpty ? null : _noteController.text,
        'payment_method_id': int.parse(_selectedMethodId!),
      };

      await ref
          .read(invoiceServiceProvider)
          .updatePayment(widget.payment.id, updateData);

      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el pago: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
