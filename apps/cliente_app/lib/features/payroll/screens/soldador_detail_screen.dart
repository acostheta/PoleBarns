import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../../settings/models/truss_model.dart';
import '../widgets/payments_dialog.dart';

class SoldadorDetailScreen extends ConsumerWidget {
  final NominaSoldador item;
  const SoldadorDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(payrollRepositoryProvider);

    return StreamBuilder<NominaSoldador?>(
      stream: repo.getSoldadorStream(item.id),
      initialData: item,
      builder: (context, snapshot) {
        final currentItem = snapshot.data ?? item;
        final double balance =
            (currentItem.total ?? 0.0) - (currentItem.pagoParcial ?? 0.0);
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: AppStyles.stoneWhite,
          appBar: AppBar(
            title: const Text(
              'Detalle de Servicio - Soldador',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
                fontSize: 18,
              ),
            ),
            backgroundColor: AppStyles.primaryForest,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              Container(
                height: 4,
                color: AppStyles.secondaryEarth,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppStyles.paleSage),
                              boxShadow: [
                                BoxShadow(
                                  color: AppStyles.primaryForest
                                      .withValues(alpha: 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                          empName = emp['full_name'] ??
                                              emp['name'] ??
                                              '-';
                                        }
                                      }
                                      final children1 = [
                                        _buildDetailItem(
                                            'FECHA DEL SERVICIO',
                                            DateFormat('MMMM d, yyyy')
                                                .format(currentItem.fecha)),
                                        _buildDetailItem('EMPLEADO', empName),
                                        _buildDetailItem(
                                          'FORMA DE PAGO',
                                          currentItem.formaPago ?? 'PENDIENTE',
                                          valueStyle: const TextStyle(
                                            color: AppStyles.secondaryEarth,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      ];
                                      return isMobile
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: children1
                                                  .map((c) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                bottom: 24),
                                                        child: c,
                                                      ))
                                                  .toList(),
                                            )
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: children1
                                                  .map((c) => Expanded(child: c))
                                                  .toList(),
                                            );
                                    }),
                                const SizedBox(height: 24),
                                const Divider(color: AppStyles.paleSage),
                                const SizedBox(height: 24),
                                Builder(builder: (context) {
                                  final children2 = [
                                    _buildDetailItem(
                                      'TOTAL A PAGAR',
                                      NumberFormat.simpleCurrency()
                                          .format(currentItem.total ?? 0.0),
                                      valueStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Manrope',
                                          color: Color(0xFF166534)),
                                    ),
                                    _buildDetailItem(
                                      'PAGADO',
                                      NumberFormat.simpleCurrency()
                                          .format(currentItem.pagoParcial ?? 0.0),
                                      valueStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Manrope'),
                                    ),
                                    _buildDetailItem(
                                      'SALDO',
                                      NumberFormat.simpleCurrency().format(balance),
                                      valueStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Manrope',
                                          color: balance > 0
                                              ? const Color(0xFF991B1B)
                                              : AppStyles.primaryForest),
                                    ),
                                  ];
                                  return isMobile
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: children2
                                              .map((c) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 24),
                                                    child: c,
                                                  ))
                                              .toList(),
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: children2
                                              .map((c) => Expanded(child: c))
                                              .toList(),
                                        );
                                }),
                                if (currentItem.notas != null &&
                                    currentItem.notas!.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(color: AppStyles.paleSage),
                                  const SizedBox(height: 24),
                                  _buildDetailItem('NOTAS', currentItem.notas!),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppStyles.secondaryEarth,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Detalle de Trusses',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Manrope',
                                  color: AppStyles.primaryForest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<SpecificTruss>>(
                            stream: repo.getSpecificTrussesBySoldadorStream(
                                currentItem.id),
                            builder: (context, trussSnapshot) {
                              if (trussSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !trussSnapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (trussSnapshot.hasError) {
                                return Text('Error: ${trussSnapshot.error}');
                              }
                              final trusses = trussSnapshot.data ?? [];
                              if (trusses.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppStyles.paleSage),
                                  ),
                                  child: const Center(
                                      child: Text(
                                          'No hay trusses específicos registrados.',
                                          style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontFamily: 'Manrope'))),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppStyles.paleSage),
                                ),
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                  AppStyles.paleSage),
                                          headingTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppStyles.primaryForest,
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.5,
                                          ),
                                          columns: const [
                                            DataColumn(label: Text('TRUSS')),
                                            DataColumn(
                                                label: Text('CANT.'),
                                                numeric: true),
                                            DataColumn(
                                                label: Text('PRECIO U.'),
                                                numeric: true),
                                            DataColumn(
                                                label: Text('SUBTOTAL'),
                                                numeric: true),
                                          ],
                                          rows: trusses.map((t) {
                                            final subtotal =
                                                t.quantity * t.unitPrice;
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(t.trussName,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily:
                                                              'Manrope')),
                                                ),
                                                DataCell(Text(
                                                    t.quantity.toString())),
                                                DataCell(Text(NumberFormat
                                                    .simpleCurrency()
                                                    .format(t.unitPrice))),
                                                DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(subtotal),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontFamily: 'Manrope',
                                                      color:
                                                          AppStyles.primaryForest),
                                                )),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppStyles.secondaryEarth,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Historial de Pagos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Manrope',
                                      color: AppStyles.primaryForest,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showPaymentsDialog(
                                    context, balance, currentItem.id),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('AÑADIR PAGO'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyles.secondaryEarth,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<NominaPago>>(
                            stream: repo.getPaymentsForSoldador(currentItem.id),
                            builder: (context, paymentSnapshot) {
                              if (paymentSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !paymentSnapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (paymentSnapshot.hasError) {
                                return Text('Error: ${paymentSnapshot.error}');
                              }
                              final payments = paymentSnapshot.data ?? [];
                              if (payments.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppStyles.paleSage),
                                  ),
                                  child: const Center(
                                      child: Text(
                                          'No hay pagos registrados para este servicio.',
                                          style: TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontFamily: 'Manrope'))),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppStyles.paleSage),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppStyles.primaryForest
                                          .withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                  AppStyles.paleSage),
                                          headingTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppStyles.primaryForest,
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.5,
                                          ),
                                          columns: const [
                                            DataColumn(label: Text('FECHA')),
                                            DataColumn(label: Text('MONTO')),
                                            DataColumn(label: Text('MÉTODO')),
                                            DataColumn(label: Text('Nº REF')),
                                            DataColumn(label: Text('NOTA')),
                                            DataColumn(label: Text('ACCIÓN')),
                                          ],
                                          rows: payments.map((p) {
                                            final displayDate =
                                                p.fechaPago ?? p.createdAt;
                                            return DataRow(
                                                onSelectChanged: (_) =>
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          EditPaymentDialog(
                                                              payment: p),
                                                    ),
                                                cells: [
                                                  DataCell(Text(displayDate !=
                                                          null
                                                      ? DateFormat('MM/dd/yyyy')
                                                          .format(displayDate)
                                                      : '-')),
                                                  DataCell(Text(
                                                      NumberFormat.simpleCurrency()
                                                          .format(p.amount),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Color(
                                                              0xFF166534)))),
                                                  DataCell(
                                                      Text(p.metodoPago ?? '-')),
                                                  DataCell(
                                                      Text(p.category ?? '-')),
                                                  DataCell(Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxWidth: 150),
                                                    child: Text(p.nota ?? '-',
                                                        overflow:
                                                            TextOverflow.ellipsis),
                                                  )),
                                                  DataCell(Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit_outlined,
                                                            color: AppStyles
                                                                .primaryForest,
                                                            size: 18),
                                                        onPressed: () =>
                                                            showDialog(
                                                          context: context,
                                                          builder: (_) =>
                                                              EditPaymentDialog(
                                                                  payment: p),
                                                        ),
                                                        tooltip: 'Editar Pago',
                                                        padding: EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.delete_outline,
                                                            color: Color(
                                                                0xFF991B1B),
                                                            size: 18),
                                                        onPressed: () =>
                                                            _deletePayment(
                                                                context, ref, p.id),
                                                        tooltip: 'Eliminar Pago',
                                                        padding: EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
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
                              );
                            },
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppStyles.secondaryEarth,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            fontFamily: 'Manrope',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                  color: AppStyles.primaryForest),
        ),
      ],
    );
  }

  void _showPaymentsDialog(
      BuildContext context, double balance, String soldadorId) {
    showDialog(
      context: context,
      builder: (context) => PaymentsDialog(
        soldadorId: soldadorId,
        type: 'Soldadura',
        initialAmount: balance > 0 ? balance : null,
      ),
    );
  }

  Future<void> _deletePayment(
      BuildContext context, WidgetRef ref, String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: AppStyles.stoneWhite,
        title: const Text(
          'Eliminar Pago',
          style: TextStyle(
            color: AppStyles.primaryForest,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        content: const Text(
          '¿Está seguro de que desea eliminar este pago?',
          style: TextStyle(fontFamily: 'Manrope'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(payrollRepositoryProvider).deletePayment(paymentId);
    }
  }
}
