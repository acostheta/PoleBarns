import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/account_payable_model.dart';
import '../providers/accounts_payable_provider.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../project_tracking/providers/project_providers.dart';

class EditAccountDialog extends ConsumerStatefulWidget {
  final AccountPayableModel account;

  const EditAccountDialog({super.key, required this.account});

  @override
  ConsumerState<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends ConsumerState<EditAccountDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _refController;
  late DateTime _selectedDate;
  String? _selectedProviderId;
  String? _selectedProjectId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.account.totalAmount.toString());
    _refController =
        TextEditingController(text: widget.account.invoiceInternRef ?? '');
    _selectedDate = widget.account.invoiceDate;
    _selectedProviderId = widget.account.providerId;
    _selectedProjectId = widget.account.projectId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(providersListProvider);
    final projectsAsync = ref.watch(projectListProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Editar Cuenta por Pagar',
                      style: AppStyles.dialogTitleStyle),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Provider Dropdown
              const Text('Proveedor', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              providersAsync.when(
                data: (providers) => DropdownButtonFormField<String>(
                  value: _selectedProviderId,
                  decoration: AppStyles.inputDecoration(),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: providers
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProviderId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 20),

              // Project Dropdown (Optional)
              const Text('Proyecto (Opcional)', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: AppStyles.inputDecoration()
                      .copyWith(hintText: 'Seleccionar proyecto...'),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sin proyecto')),
                    ...projects.map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.address))),
                  ],
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 20),

              // Invoice Date
              const Text('Fecha de Factura', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
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

              // Total Amount
              const Text('Monto Total', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: AppStyles.inputDecoration()
                    .copyWith(prefixText: r'$ ', hintText: '0.00'),
              ),

              const SizedBox(height: 20),

              // Invoice Reference
              const Text('Referencia de Factura (Opcional)',
                  style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: _refController,
                decoration: AppStyles.inputDecoration()
                    .copyWith(hintText: 'Ej: INV-001'),
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
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un proveedor')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(accountsPayableRepositoryProvider).updateAccount(
            accountId: widget.account.id,
            providerId: _selectedProviderId!,
            invoiceDate: _selectedDate,
            totalAmount: amount,
            projectId: _selectedProjectId,
            invoiceInternRef:
                _refController.text.isEmpty ? null : _refController.text,
          );

      ref.invalidate(accountPayableDetailProvider(widget.account.id));
      ref.invalidate(accountsPayableListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta actualizada exitosamente')),
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
