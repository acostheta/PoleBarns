import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../widgets/payments_dialog.dart';

class PagoDiarioDetailScreen extends ConsumerWidget {
  final NominaPagoDiario item;
  const PagoDiarioDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(payrollRepositoryProvider);

    return StreamBuilder<NominaPagoDiario?>(
      stream: repo.getPagoDiarioStreamById(item.id),
      initialData: item,
      builder: (context, snapshot) {
        final currentItem = snapshot.data ?? item;
        final balance =
            (currentItem.monto ?? 0.0) - (currentItem.pagoParcial ?? 0.0);
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle de Pago Diario'),
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
                // Detalles del Servicio Section
                const Text(
                  'Detalles del Servicio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                      // Row 1: Fecha, Empleado, Días trabajados, Método de pago
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: repo.getEmployeesStream().first,
                          builder: (context, snapshot) {
                            String empName = '-';
                            if (snapshot.hasData) {
                              final emp = snapshot.data!.firstWhere(
                                  (e) =>
                                      e['id'].toString() ==
                                      currentItem.idEmpleado,
                                  orElse: () => {});
                              if (emp.isNotEmpty) {
                                empName =
                                    emp['full_name'] ?? emp['name'] ?? '-';
                              }
                            }
                            final children1 = [
                              _buildDetailItem(
                                  'Fecha',
                                  DateFormat('MM/dd/yyyy')
                                      .format(currentItem.fecha)),
                              _buildDetailItem('Empleado', empName),
                              _buildDetailItem('Días',
                                  currentItem.dias?.toString() ?? '-'),
                              _buildDetailItem('Método de Pago',
                                  currentItem.formaPago ?? '-'),
                            ];
                            return isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: children1
                                        .map((c) => Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
                                              child: c,
                                            ))
                                        .toList(),
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: children1
                                        .map((c) => Expanded(child: c))
                                        .toList(),
                                  );
                          }),
                      const SizedBox(height: 24),
                      // Row 2: Total a pagar, Pagado, Saldo
                      Builder(builder: (context) {
                        final children2 = [
                          _buildDetailItem(
                            'Total a Pagar',
                            NumberFormat.simpleCurrency()
                                .format(currentItem.monto),
                            valueStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          _buildDetailItem(
                            'Pagado',
                            NumberFormat.simpleCurrency()
                                .format(currentItem.pagoParcial ?? 0),
                            valueStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          _buildDetailItem(
                            'Saldo',
                            NumberFormat.simpleCurrency().format(balance),
                            valueStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: balance > 0 ? Colors.red : Colors.black,
                            ),
                          ),
                        ];
                        return isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children2
                                    .map((c) => Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: c,
                                        ))
                                    .toList(),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children2
                                    .map((c) => Expanded(child: c))
                                    .toList(),
                              );
                      }),
                      // Row 3: Notas
                      if (currentItem.notas != null &&
                          currentItem.notas!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildDetailItem('Notas', currentItem.notas!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Historial de Pagos Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historial de Pagos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showPaymentsDialog(context, currentItem.id, balance),
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
                  stream: repo.getPaymentsForPagoDiario(currentItem.id),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                            final displayDate = p.fechaPago ?? p.createdAt;
                            return DataRow(
                              onSelectChanged: (_) => showDialog(
                                context: context,
                                builder: (_) => EditPaymentDialog(payment: p),
                              ),
                              cells: [
                              DataCell(Text(displayDate != null
                                  ? DateFormat('MM/dd/yyyy').format(displayDate)
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
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blue, size: 18),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => EditPaymentDialog(payment: p),
                                    ),
                                    tooltip: 'Editar Pago',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 18),
                                    onPressed: () =>
                                        _deletePayment(context, ref, p.id),
                                    tooltip: 'Eliminar Pago',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                              ),
                            );
                          },
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

  void _showPaymentsDialog(
      BuildContext context, String itemId, double balance) {
    showDialog(
      context: context,
      builder: (context) => PaymentsDialog(
        pagoDiarioId: itemId,
        type: 'Pago Diario',
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
