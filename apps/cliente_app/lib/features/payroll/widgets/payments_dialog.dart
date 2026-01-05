import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _addPayment() async {
    if (_amountCtrl.text.isEmpty) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);
    final stream = widget.type == 'Soldadura'
        ? repo.getPaymentsForSoldador(widget.soldadorId!)
        : repo.getPaymentsForInstalacion(widget.instalacionId!);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 500,
        height: 600,
        child: Column(
          children: [
            Text('Pagos - ${widget.type}',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<PaymentDestajo>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final payments = snapshot.data!;
                  return ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return ListTile(
                        title: Text('\$${p.amount}'),
                        subtitle: Text(
                            '${p.metodoPago ?? '-'} (${p.category ?? '-'})'),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Text('Agregar Pago',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _methodCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Método'))),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _categoryCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Categoría'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(labelText: 'Nota'))),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _addPayment, child: const Text('Agregar Pago')),
          ],
        ),
      ),
    );
  }
}
