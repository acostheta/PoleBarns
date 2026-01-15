import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';

class AddPaymentDialog extends ConsumerStatefulWidget {
  final int invoiceId;
  final VoidCallback onAdded;
  const AddPaymentDialog(
      {super.key, required this.invoiceId, required this.onAdded});

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _tipo = 'Abono';
  bool _isLoading = false;

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
                const Text('Registrar Pago', style: AppStyles.dialogTitleStyle),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Tipo de Transacción', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
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
            _buildTextField('Monto', _amountController,
                keyboardType: TextInputType.number, prefixText: '\$ '),
            const SizedBox(height: 24),
            _buildTextField('Nota / Comentario', _noteController, maxLines: 2),
            const SizedBox(height: 40),
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
                    : const Text('Confirmar Pago'),
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
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border:
              Border.all(color: isSelected ? color : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? prefixText, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          keyboardType: keyboardType,
          decoration:
              AppStyles.inputDecoration().copyWith(prefixText: prefixText),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final pay = InvoicePaymentModel(
        id: 0,
        idInvoice: widget.invoiceId,
        tipo: _tipo,
        amount: amount,
        nota: _noteController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(invoiceServiceProvider).addPayment(pay);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
}
