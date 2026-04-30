import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../../../config/ui_helpers.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../providers/payroll_summary_provider.dart';
import '../widgets/payments_dialog.dart';
import '../widgets/pagos_soldadores_form_dialog.dart';
import 'soldador_detail_screen.dart';

class PagosSoldadoresScreen extends ConsumerStatefulWidget {
  const PagosSoldadoresScreen({super.key});

  @override
  ConsumerState<PagosSoldadoresScreen> createState() =>
      _PagosSoldadoresScreenState();
}

class _PagosSoldadoresScreenState extends ConsumerState<PagosSoldadoresScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);
    final periodFilter = ref.watch(payrollPeriodFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration:
                  AppStyles.inputDecoration(hintText: 'Buscar por empleado...')
                      .copyWith(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaSoldador>>(
              stream: repo.getSoldadoresStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: repo.getEmployeesStream(),
                    builder: (context, empSnapshot) {
                      final employees = empSnapshot.data ?? [];
                      final empMap = {
                        for (var e in employees)
                          e['id'].toString():
                              (e['full_name'] ?? e['name'])?.toString() ?? 'S/N'
                      };

                      final items = snapshot.data!.where((item) {
                        if (!isDateInFilterRange(item.fecha, periodFilter)) return false;
                        
                        final empName =
                            empMap[item.idEmpleado]?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery);
                      }).toList();

                      if (items.isEmpty) {
                        return const Center(child: Text('No hay registros.'));
                      }

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.grey.shade200,
                                      ),
                                      child: DataTable(
                                        showCheckboxColumn: false,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                                Colors.grey.shade50),
                                        dataRowMinHeight: 40,
                                        dataRowMaxHeight: 52,
                                        headingRowHeight: 48,
                                        columnSpacing: 16,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(label: Text('FECHA')),
                                          DataColumn(label: Text('EMPLEADO')),
                                          DataColumn(label: Text('CANTIDAD')),
                                          DataColumn(label: Text('PRECIO')),
                                          DataColumn(label: Text('MÉTODO')),
                                          DataColumn(label: Text('TOTAL')),
                                          DataColumn(label: Text('PAGADO')),
                                          DataColumn(label: Text('SALDO')),
                                          DataColumn(label: Text('ACCIONES')),
                                        ],
                                        rows: items.map((item) {
                                          final total = item.cantidad != null &&
                                                  item.montoUnitario != null
                                              ? item.cantidad! *
                                                  item.montoUnitario!
                                              : 0.0;
                                          final saldo =
                                              total - (item.pagoParcial ?? 0);
                                          final empName =
                                              empMap[item.idEmpleado] ??
                                                  'Desconocido';

                                          return DataRow(
                                            onSelectChanged: (_) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SoldadorDetailScreen(
                                                          item: item),
                                                ),
                                              );
                                            },
                                            cells: [
                                              DataCell(Text(
                                                  DateFormat('MM/dd/yyyy')
                                                      .format(item.fecha))),
                                              DataCell(Text(empName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
                                              DataCell(Text(
                                                  item.cantidad?.toString() ??
                                                      '-')),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(
                                                          item.montoUnitario ??
                                                              0))),
                                              DataCell(
                                                  Text(item.formaPago ?? '-')),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(total),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(
                                                          item.pagoParcial ??
                                                              0),
                                                  style: const TextStyle(
                                                      color: Colors.green))),
                                              DataCell(Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(saldo),
                                                style: TextStyle(
                                                    color: saldo > 0
                                                        ? Colors.red
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.payments_outlined,
                                                        color: Colors.green,
                                                        size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        _showPaymentsDialog(
                                                            context, item),
                                                    tooltip:
                                                        'Ver/Agregar Pagos',
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.edit_outlined,
                                                        color: Colors.blue,
                                                        size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        _showEditDialog(
                                                            context, item),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () =>
                                                        _confirmDelete(item),
                                                  ),
                                                ],
                                              )),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(NominaSoldador item) async {
    final confirm = await AppBottomSheet.showConfirm(
      context: context,
      title: 'Eliminar Registro',
      message: '¿Está seguro de que desea eliminar este registro de pago a soldador?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (confirm == true) {
      await ref.read(payrollRepositoryProvider).deleteSoldador(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaSoldador? item) {
    AppBottomSheet.show(
      context: context,
      child: PagosSoldadoresFormDialog(item: item),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaSoldador item) {
    final total = (item.cantidad ?? 0.0) * (item.montoUnitario ?? 0.0);
    final balance = total - (item.pagoParcial ?? 0.0);
    AppBottomSheet.show(
      context: context,
      child: PaymentsDialog(
        soldadorId: item.id,
        type: 'Soldadura',
        initialAmount: balance > 0 ? balance : null,
      ),
    );
  }
}
