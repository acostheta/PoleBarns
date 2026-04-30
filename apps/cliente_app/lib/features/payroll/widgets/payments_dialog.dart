import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../../settings/repositories/settings_repository.dart';
import '../../../config/ui_helpers.dart';

class PaymentsDialog extends ConsumerStatefulWidget {
  final String? soldadorId;
  final String? instalacionId;
  final String? pagoDiarioId;
  final String? choferId;
  final String type; // 'Soldadura', 'Instalación', 'Pago Diario', 'Chofer'
  final double? initialAmount;

  const PaymentsDialog({
    super.key,
    this.soldadorId,
    this.instalacionId,
    this.pagoDiarioId,
    this.choferId,
    required this.type,
    this.initialAmount,
  });

  @override
  ConsumerState<PaymentsDialog> createState() => _PaymentsDialogState();
}

class _PaymentsDialogState extends ConsumerState<PaymentsDialog> {
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedMethod;
  DateTime? _fechaPago;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountCtrl.text = widget.initialAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    if (_amountCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final p = NominaPago(
        id: '',
        tipo: widget.type,
        idNominaSoldadura: widget.soldadorId,
        idNominaInstalacion: widget.instalacionId,
        idNominaPagoDiario: widget.pagoDiarioId,
        idNominaChofer: widget.choferId,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        metodoPago: _selectedMethod,
        category: _categoryCtrl.text,
        nota: _noteCtrl.text,
        fechaPago: _fechaPago,
      );
      await ref.read(payrollRepositoryProvider).createPayment(p);
      _amountCtrl.clear();
      _categoryCtrl.clear();
      _noteCtrl.clear();
      setState(() {
        _selectedMethod = null;
        _fechaPago = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayment(String id) async {
    final confirm = await AppBottomSheet.showConfirm(
      context: context,
      title: 'Eliminar Pago',
      message: '¿Está seguro de que desea eliminar este pago?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (confirm == true && mounted) {
      await ref.read(payrollRepositoryProvider).deletePayment(id);
    }
  }

  void _showEditPaymentDialog(NominaPago payment) {
    AppBottomSheet.show(
      context: context,
      child: EditPaymentDialog(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    final stream = switch (widget.type) {
      'Soldadura' => repo.getPaymentsForSoldador(widget.soldadorId!),
      'Instalación' => repo.getPaymentsForInstalacion(widget.instalacionId!),
      'Pago Diario' => repo.getPaymentsForPagoDiario(widget.pagoDiarioId!),
      'Chofer' => repo.getPaymentsForChofer(widget.choferId!),
      _ => const Stream<List<NominaPago>>.empty(),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pagos - ${widget.type}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173124))),
          const SizedBox(height: 24),
          // Existing payments list
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: StreamBuilder<List<NominaPago>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final payments = snapshot.data!;
                  if (payments.isEmpty) {
                    return const Center(
                        child: Text('No hay pagos registrados',
                            style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      final dateStr = p.fechaPago != null
                          ? DateFormat('MM/dd/yyyy').format(p.fechaPago!)
                          : (p.createdAt != null
                              ? DateFormat('MM/dd/yyyy').format(p.createdAt!)
                              : '-');
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.attach_money,
                                color: Colors.green, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '\$${p.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    '${p.metodoPago ?? "Efectivo"} • ${p.category?.isNotEmpty == true ? p.category! : "-"}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (p.nota != null && p.nota!.isNotEmpty)
                            Tooltip(
                              message: p.nota!,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.info_outline,
                                    size: 16, color: Colors.grey),
                              ),
                            ),
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 17, color: Colors.blue),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            tooltip: 'Editar pago',
                            onPressed: () => _showEditPaymentDialog(p),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 17, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            tooltip: 'Eliminar pago',
                            onPressed: () => _deletePayment(p.id),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Registrar Nuevo Pago', style: AppStyles.labelStyle),
          const SizedBox(height: 12),
          // Amount + Method row
          Row(
            children: [
              Expanded(
                child: _buildTextField('Monto', _amountCtrl,
                    keyboardType: TextInputType.number, prefixText: '\$ '),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Método',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    methodsAsync.when(
                      data: (methods) => DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        items: methods
                            .map((m) => DropdownMenuItem(
                                  value: m.name,
                                  child: Text(m.name,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMethod = v),
                        decoration:
                            AppStyles.inputDecoration(hintText: 'Seleccionar'),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        isExpanded: true,
                      ),
                      loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, s) => const Text('Error',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ref + Note row
          Row(
            children: [
              Expanded(
                child: _buildTextField('Nº Ref', _categoryCtrl,
                    hintText: 'Ej: 12345'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Nota', _noteCtrl),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fecha de Pago
          _buildDateField(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addPayment,
              style: AppStyles.primaryButtonStyle,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Agregar Pago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha de Pago',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fechaPago ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _fechaPago = picked);
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fechaPago != null
                      ? DateFormat('MM/dd/yyyy').format(_fechaPago!)
                      : 'Seleccionar fecha...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _fechaPago != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? prefixText, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          keyboardType: keyboardType,
          decoration: AppStyles.inputDecoration(hintText: hintText).copyWith(
            prefixText: prefixText,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Payment Dialog (public – used by detail screens too)
// ---------------------------------------------------------------------------

class EditPaymentDialog extends ConsumerStatefulWidget {
  final NominaPago payment;
  const EditPaymentDialog({super.key, required this.payment});

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _noteCtrl;
  String? _selectedMethod;
  DateTime? _fechaPago;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    _amountCtrl = TextEditingController(text: p.amount.toStringAsFixed(2));
    _categoryCtrl = TextEditingController(text: p.category ?? '');
    _noteCtrl = TextEditingController(text: p.nota ?? '');
    _selectedMethod = p.metodoPago;
    _fechaPago = p.fechaPago ?? p.createdAt;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final updated = NominaPago(
        id: widget.payment.id,
        tipo: widget.payment.tipo,
        idNominaSoldadura: widget.payment.idNominaSoldadura,
        idNominaInstalacion: widget.payment.idNominaInstalacion,
        idNominaPagoDiario: widget.payment.idNominaPagoDiario,
        idNominaChofer: widget.payment.idNominaChofer,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        metodoPago: _selectedMethod,
        category: _categoryCtrl.text,
        nota: _noteCtrl.text,
        createdAt: widget.payment.createdAt,
        fechaPago: _fechaPago,
      );
      await ref
          .read(payrollRepositoryProvider)
          .updatePayment(widget.payment.id, updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar Pago',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173124))),
            const SizedBox(height: 32),
            // Amount
            _buildTextField('Monto', _amountCtrl,
                keyboardType: TextInputType.number, prefixText: '\$ '),
            const SizedBox(height: 16),
            // Method
            const Text('Método de Pago', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            methodsAsync.when(
              data: (methods) {
                if (_selectedMethod != null &&
                    !methods.any((m) => m.name == _selectedMethod)) {
                  _selectedMethod = null;
                }
                return DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  items: methods
                      .map((m) => DropdownMenuItem(
                            value: m.name,
                            child: Text(m.name,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMethod = v),
                  decoration:
                      AppStyles.inputDecoration(hintText: 'Seleccionar'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  isExpanded: true,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Error cargando métodos'),
            ),
            const SizedBox(height: 16),
            // Ref
            _buildTextField('Nº Referencia', _categoryCtrl,
                hintText: 'Ej: 12345'),
            const SizedBox(height: 16),
            // Nota
            _buildTextField('Nota', _noteCtrl),
            const SizedBox(height: 16),
            // Fecha de Pago
            const Text('Fecha de Pago', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaPago ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _fechaPago = picked);
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
                    Text(
                      _fechaPago != null
                          ? DateFormat('MM/dd/yyyy').format(_fechaPago!)
                          : 'Seleccionar fecha...',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _fechaPago != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.calendar_month,
                        size: 20, color: Colors.grey),
                  ],
                ),
              ),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? prefixText, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          keyboardType: keyboardType,
          decoration: AppStyles.inputDecoration(hintText: hintText)
              .copyWith(prefixText: prefixText),
        ),
      ],
    );
  }
}
