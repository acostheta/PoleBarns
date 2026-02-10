import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';

class PaymentsDialog extends ConsumerStatefulWidget {
  final String? soldadorId;
  final String? instalacionId;
  final String type; // 'Soldadura' or 'Instalación'

  const PaymentsDialog({
    super.key,
    this.soldadorId,
    this.instalacionId,
    required this.type,
  });

  @override
  ConsumerState<PaymentsDialog> createState() => _PaymentsDialogState();
}

class _PaymentsDialogState extends ConsumerState<PaymentsDialog> {
  final _amountCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPayment() async {
    if (_amountCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final p = PaymentDestajo(
        id: '',
        tipo: widget.type,
        idNominaSoldadura: widget.soldadorId,
        idNominaInstalacion: widget.instalacionId,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        metodoPago: _methodCtrl.text,
        category: _categoryCtrl.text,
        nota: _noteCtrl.text,
      );
      await ref.read(payrollRepositoryProvider).createPaymentDestajo(p);
      _amountCtrl.clear();
      _methodCtrl.clear();
      _categoryCtrl.clear();
      _noteCtrl.clear();
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
    final repo = ref.watch(payrollRepositoryProvider);
    final stream = widget.type == 'Soldadura'
        ? repo.getPaymentsForSoldador(widget.soldadorId!)
        : repo.getPaymentsForInstalacion(widget.instalacionId!);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pagos - ${widget.type}',
                      style: AppStyles.dialogTitleStyle),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: StreamBuilder<List<PaymentDestajo>>(
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
                        padding: const EdgeInsets.all(16),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.attach_money,
                                    color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('\$${p.amount}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${p.metodoPago ?? "Efectivo"} • ${p.category ?? "General"}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (p.nota != null && p.nota != '')
                                Tooltip(
                                  message: p.nota,
                                  child: const Icon(Icons.info_outline,
                                      size: 18, color: Colors.grey),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              const Text('Registrar Nuevo Pago', style: AppStyles.labelStyle),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Monto', _amountCtrl,
                        keyboardType: TextInputType.number, prefixText: '\$ '),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Método', _methodCtrl,
                        hintText: 'Ej: Zelle, Cash'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Categoría', _categoryCtrl,
                        hintText: 'Ej: Abono'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Nota', _noteCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? prefixText, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
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
