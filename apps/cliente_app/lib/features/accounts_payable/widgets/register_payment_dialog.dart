import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un método de pago')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      if (amount > widget.account.currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El monto no puede exceder el saldo pendiente')),
        );
        return;
      }

      try {
        final repo = ref.read(accountsPayableRepositoryProvider);
        await repo.addPayment(
          apId: widget.account.id,
          date: _paymentDate,
          amount: amount,
          paymentMethodId: _selectedMethodId,
          notes: _notesController.text,
        );
        if (mounted) Navigator.of(context).pop();
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

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Abonar: ${widget.account.invoiceInternRef ?? "Sin Ref"}',
                        style:
                            AppStyles.dialogTitleStyle.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Saldo Pendiente: \$${widget.account.currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // Payment Method
                const Text('Método de Pago', style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                methodsAsync.when(
                  data: (methods) => DropdownButtonFormField<String>(
                    value: _selectedMethodId,
                    items: methods
                        .map<DropdownMenuItem<String>>((PaymentMethodModel m) {
                      return DropdownMenuItem<String>(
                        value: m.id,
                        child:
                            Text(m.name, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMethodId = val),
                    decoration: AppStyles.inputDecoration(),
                    validator: (val) => val == null ? 'Requerido' : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading methods: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),

                // Date Picker
                _buildDateField('Fecha del Pago', _paymentDate,
                    (d) => setState(() => _paymentDate = d)),
                const SizedBox(height: 24),

                // Amount
                _buildTextField(
                  'Monto a Abonar',
                  _amountController,
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '\$ ',
                ),
                const SizedBox(height: 24),

                // Notes
                _buildTextField('Notas (Opcional)', _notesController,
                    maxLines: 2),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: AppStyles.primaryButtonStyle,
                    child: const Text('Registrar Abono'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false,
      TextInputType? keyboardType,
      String? prefixText,
      int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          keyboardType: keyboardType,
          validator: required
              ? (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (keyboardType?.decimal == true) {
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Monto inválido';
                  }
                  return null;
                }
              : null,
          decoration: AppStyles.inputDecoration().copyWith(
            prefixText: prefixText,
          ),
        )
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime date, Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd/yyyy').format(date),
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
                const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
              ],
            ),
          ),
        )
      ],
    );
  }
}
