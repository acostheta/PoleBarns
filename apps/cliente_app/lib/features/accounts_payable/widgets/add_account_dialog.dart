import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../settings/models/provider_model.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../providers/accounts_payable_provider.dart';

class AddAccountDialog extends ConsumerStatefulWidget {
  final String? initialProjectId;
  final int? initialInvoiceId;
  const AddAccountDialog(
      {super.key, this.initialProjectId, this.initialInvoiceId});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProviderId;
  String? _selectedProjectId;
  int? _selectedInvoiceId;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    _selectedInvoiceId = widget.initialInvoiceId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
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
        return;
      }

      try {
        await ref.read(accountsPayableListProvider.notifier).addAccount(
              providerId: _selectedProviderId!,
              projectId: _selectedProjectId,
              invoiceId: _selectedInvoiceId,
              invoiceDate: _selectedDate,
              totalAmount: amount,
              invoiceInternRef:
                  _refController.text.isNotEmpty ? _refController.text : null,
            );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersListProvider);
    final invoicesAsync = ref.watch(invoicesStreamProvider);

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
                    const Text('Registrar Cuenta',
                        style: AppStyles.dialogTitleStyle),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 32),

                // Provider Dropdown
                const Text('Proveedor', style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                providersAsync.when(
                  data: (providers) => DropdownButtonFormField<String>(
                    value: _selectedProviderId,
                    items: providers
                        .map<DropdownMenuItem<String>>((ProviderModel p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child:
                            Text(p.name, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedProviderId = val),
                    decoration: AppStyles.inputDecoration(),
                    validator: (val) => val == null ? 'Requerido' : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),

                // Project Dropdown
                const Text('Relacionar a Invoice (Opcional)',
                    style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                invoicesAsync.when(
                  data: (invoices) => DropdownButtonFormField<int>(
                    value: _selectedInvoiceId,
                    items: invoices.map<DropdownMenuItem<int>>((inv) {
                      return DropdownMenuItem<int>(
                        value: inv.id,
                        child: Text(
                            'Factura #${inv.id} - ${inv.clientName ?? ''}',
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedInvoiceId = val;
                        if (val != null) {
                          final inv = invoices.firstWhere((i) => i.id == val);
                          _selectedProjectId = inv.idProyecto;
                        }
                      });
                    },
                    decoration: AppStyles.inputDecoration(
                        hintText: 'Seleccione un invoice'),
                    icon: const Icon(Icons.receipt_outlined),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error al cargar invoices',
                      style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),

                // Date Picker
                _buildDateField('Fecha de Factura', _selectedDate,
                    (d) => setState(() => _selectedDate = d)),
                const SizedBox(height: 24),

                // Reference
                _buildTextField(
                    'Referencia Interna (Opcional)', _refController),
                const SizedBox(height: 24),

                // Amount
                _buildTextField(
                  'Monto Total',
                  _amountController,
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '\$ ',
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: AppStyles.primaryButtonStyle,
                    child: const Text('Registrar Cuenta'),
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
      String? prefixText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          keyboardType: keyboardType,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Requerido' : null
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
