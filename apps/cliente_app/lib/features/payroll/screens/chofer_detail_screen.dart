import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../widgets/payments_dialog.dart';

class ChoferDetailScreen extends ConsumerWidget {
  final NominaChofer item;
  const ChoferDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(payrollRepositoryProvider);

    return StreamBuilder<NominaChofer?>(
      stream: repo.getChoferStreamById(item.id),
      initialData: item,
      builder: (context, snapshot) {
        final currentItem = snapshot.data ?? item;
        final total =
            (currentItem.horas ?? 0.0) * (currentItem.ratePorHora ?? 0.0);
        final balance = total - (currentItem.pagoParcial ?? 0.0);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle de Servicio - Chofer'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Fecha, Empleado, Horas, Rate p/h
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: repo.getEmployeesStream().first,
                          builder: (context, empSnapshot) {
                            String empName = '-';
                            if (empSnapshot.hasData) {
                              final emp = empSnapshot.data!.firstWhere(
                                  (e) =>
                                      e['id'].toString() ==
                                      currentItem.idEmpleado,
                                  orElse: () => {});
                              if (emp.isNotEmpty) {
                                empName =
                                    emp['full_name'] ?? emp['name'] ?? '-';
                              }
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                      'Fecha',
                                      DateFormat('MM/dd/yyyy')
                                          .format(currentItem.fecha)),
                                ),
                                Expanded(
                                  child: _buildDetailItem('Empleado', empName),
                                ),
                                Expanded(
                                  child: _buildDetailItem('Horas',
                                      currentItem.horas?.toString() ?? '-'),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                      'Rate p/h',
                                      NumberFormat.simpleCurrency().format(
                                          currentItem.ratePorHora ?? 0.0)),
                                ),
                              ],
                            );
                          }),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      // Row 2: Total a Pagar, Pagado, Saldo
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Total a Pagar',
                              NumberFormat.simpleCurrency().format(total),
                              valueStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Pagado',
                              NumberFormat.simpleCurrency()
                                  .format(currentItem.pagoParcial ?? 0.0),
                              valueStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Saldo',
                              NumberFormat.simpleCurrency().format(balance),
                              valueStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      balance > 0 ? Colors.red : Colors.black),
                            ),
                          ),
                        ],
                      ),
                      // Row 3: Tareas (as Notes)
                      if (currentItem.tareas != null &&
                          currentItem.tareas!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildDetailItem(
                            'Notas adicionales', currentItem.tareas!),
                      ],
                      if (currentItem.notas != null &&
                          currentItem.notas!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildDetailItem(
                            'Notas adicionales', currentItem.notas!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Historial de Pagos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showPaymentsDialog(context, balance),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Añadir Pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<NominaPago>>(
                  stream: repo.getPaymentsForChofer(currentItem.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final payments = snapshot.data ?? [];
                    if (payments.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                            child: Text(
                                'No hay pagos registrados para este servicio.',
                                style: TextStyle(color: Colors.grey))),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Colors.grey.shade50),
                          columns: const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Monto')),
                            DataColumn(label: Text('Método')),
                            DataColumn(label: Text('Nº Ref')),
                            DataColumn(label: Text('Nota')),
                            DataColumn(label: Text('Acción')),
                          ],
                          rows: payments.map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p.createdAt != null
                                  ? DateFormat('MM/dd/yyyy')
                                      .format(p.createdAt!)
                                  : '-')),
                              DataCell(Text(
                                  NumberFormat.simpleCurrency()
                                      .format(p.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green))),
                              DataCell(Text(p.metodoPago ?? '-')),
                              DataCell(Text(p.category ?? '-')),
                              DataCell(Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: Text(p.nota ?? '-',
                                    overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () =>
                                      _deletePayment(context, ref, p.id),
                                  tooltip: 'Eliminar Pago',
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _showPaymentsDialog(BuildContext context, double balance) {
    showDialog(
      context: context,
      builder: (context) => PaymentsDialog(
        choferId: item.id,
        type: 'Chofer',
        initialAmount: balance > 0 ? balance : null,
      ),
    );
  }

  Future<void> _deletePayment(
      BuildContext context, WidgetRef ref, String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Pago'),
        content: const Text('¿Está seguro de que desea eliminar este pago?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(payrollRepositoryProvider).deletePayment(paymentId);
    }
  }
}
