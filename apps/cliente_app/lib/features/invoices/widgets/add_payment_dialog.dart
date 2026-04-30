import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../settings/models/payment_method_model.dart';

class AddPaymentDialog extends ConsumerStatefulWidget {
  final int invoiceId;
  final double maxAmount;
  final double? initialAmount;
  final VoidCallback onAdded;
  const AddPaymentDialog({
    super.key,
    required this.invoiceId,
    required this.maxAmount,
    this.initialAmount,
    required this.onAdded,
  });

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String _tipo = 'Abono';
  String? _selectedMethodId;
  double _currentFeePercent = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount != null
          ? widget.initialAmount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar Pago', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF173124))),
          const SizedBox(height: 32),
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
          _buildTextField('Monto', _amountController,
              keyboardType: TextInputType.number, prefixText: '\$ '),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Método de Pago', style: AppStyles.labelStyle),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings?tab=2');
                },
                child: Text(
                  'Gestionar Métodos de Pago',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ref.watch(paymentMethodsListProvider).when(
                data: (methods) => DropdownButtonFormField<String>(
                  value: _selectedMethodId,
                  items: methods
                      .map<DropdownMenuItem<String>>((PaymentMethodModel m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(
                        m.serviceFee > 0
                            ? '${m.name} (${m.serviceFee}%)'
                            : m.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final method = methods.firstWhere((m) => m.id == val);
                    final oldFee = _currentFeePercent;
                    final newFee = method.serviceFee;

                    final currentTotal =
                        double.tryParse(_amountController.text) ?? 0.0;
                    // Calculate base before old fee
                    final baseAmount = currentTotal / (1 + oldFee / 100);
                    // Calculate new total
                    final newTotal = baseAmount * (1 + newFee / 100);

                    setState(() {
                      _selectedMethodId = val;
                      _currentFeePercent = newFee;
                      _amountController.text = newTotal.toStringAsFixed(2);
                    });
                  },
                  decoration: AppStyles.inputDecoration(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: const Text('Seleccionar Método',
                      style: TextStyle(fontSize: 14)),
                  isExpanded: true,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
          if (_currentFeePercent > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Fee Aplicado ($_currentFeePercent%):',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                  Text(
                    '+\$${((double.tryParse(_amountController.text) ?? 0.0) - ((double.tryParse(_amountController.text) ?? 0.0) / (1 + _currentFeePercent / 100))).toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildTextField('Nota / Comentario', _noteController, maxLines: 2),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF173124),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar Pago', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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

    if (_selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un método de pago')),
      );
      return;
    }

    // Check removed per user request: allow amounts greater than total (e.g. for fees)
    /*
    if (amount > widget.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'El monto no puede exceder el total del proyecto (\$${widget.maxAmount.toStringAsFixed(2)})'),
        ),
      );
      return;
    }
    */

    setState(() => _isLoading = true);
    try {
      final feeAmount = amount - (amount / (1 + _currentFeePercent / 100));

      final pay = InvoicePaymentModel(
        id: 0,
        idInvoice: widget.invoiceId,
        tipo: _tipo,
        amount: amount,
        metodoDePagoId: _selectedMethodId,
        nota: _noteController.text,
        feeAmount: feeAmount,
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
