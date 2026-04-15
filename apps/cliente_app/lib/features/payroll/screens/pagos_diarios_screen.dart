import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../../settings/repositories/settings_repository.dart';
import 'package:users/users.dart';
import '../widgets/payments_dialog.dart';
import '../providers/payroll_summary_provider.dart';
import 'pago_diario_detail_screen.dart';

class PagosDiariosScreen extends ConsumerStatefulWidget {
  const PagosDiariosScreen({super.key});

  @override
  ConsumerState<PagosDiariosScreen> createState() => _PagosDiariosScreenState();
}

class _PagosDiariosScreenState extends ConsumerState<PagosDiariosScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(payrollRepositoryProvider);
    final periodFilter = ref.watch(payrollPeriodFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: AppStyles.inputDecoration(
                      hintText: 'Buscar por concepto o empleado...')
                  .copyWith(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaPagoDiario>>(
              stream: repository.getPagosDiariosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: repository.getEmployeesStream(),
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
                        final concept =
                            item.conceptoPeriodo?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery) ||
                            concept.contains(_searchQuery);
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
                                          DataColumn(label: Text('CONCEPTO')),
                                          DataColumn(label: Text('F. PAGO')),
                                          DataColumn(label: Text('DÍAS')),
                                          DataColumn(label: Text('MONTO')),
                                          DataColumn(label: Text('PAGADO')),
                                          DataColumn(label: Text('SALDO')),
                                          DataColumn(label: Text('ACCIONES')),
                                        ],
                                        rows: items.map((item) {
                                          final empName =
                                              empMap[item.idEmpleado] ??
                                                  'Desconocido';
                                          return DataRow(
                                            onSelectChanged: (_) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PagoDiarioDetailScreen(
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
                                              DataCell(Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 180),
                                                child: Text(
                                                    item.conceptoPeriodo ?? '-',
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              )),
                                              DataCell(
                                                  Text(item.formaPago ?? '-')),
                                              DataCell(Text(
                                                  item.dias?.toString() ??
                                                      '-')),
                                              DataCell(Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(item.monto),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                              )),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(
                                                          item.pagoParcial ??
                                                              0),
                                                  style: const TextStyle(
                                                      color: Colors.blue))),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format((item.monto ??
                                                              0) -
                                                          (item.pagoParcial ??
                                                              0)),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
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
                                                        _deleteItem(item),
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

  Future<void> _deleteItem(NominaPagoDiario item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Registro'),
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
      await ref.read(payrollRepositoryProvider).deletePagoDiario(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaPagoDiario? item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item == null ? 'Nuevo Pago Diario' : 'Editar Pago',
                      style: AppStyles.dialogTitleStyle),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: PagoDiarioForm(item: item)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaPagoDiario item) {
    showDialog(
      context: context,
      builder: (context) => PaymentsDialog(
        pagoDiarioId: item.id,
        type: 'Pago Diario',
      ),
    );
  }
}

class PagoDiarioForm extends ConsumerStatefulWidget {
  final NominaPagoDiario? item;
  const PagoDiarioForm({super.key, this.item});

  @override
  ConsumerState<PagoDiarioForm> createState() => _PagoDiarioFormState();
}

class _PagoDiarioFormState extends ConsumerState<PagoDiarioForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _conceptoCtrl;
  late TextEditingController _montoCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _chequeCtrl;
  late TextEditingController _diasCtrl;
  String? _selectedFormaPago;
  DateTime _fecha = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.item?.idEmpleado;
    _conceptoCtrl =
        TextEditingController(text: widget.item?.conceptoPeriodo ?? '');
    _montoCtrl =
        TextEditingController(text: widget.item?.monto?.toString() ?? '');
    _notasCtrl = TextEditingController(text: widget.item?.notas ?? '');
    _chequeCtrl = TextEditingController(text: widget.item?.nroCheque ?? '');
    _diasCtrl =
        TextEditingController(text: widget.item?.dias?.toString() ?? '');
    _selectedFormaPago = widget.item?.formaPago;
    if (_selectedFormaPago != null && _selectedFormaPago!.isEmpty) {
      _selectedFormaPago = null;
    }
    if (widget.item != null) _fecha = widget.item!.fecha;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empleado', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final usersAsync = ref.watch(allUsersProvider);
                final positionsAsync = ref.watch(jobPositionsProvider);

                return usersAsync.when(
                  data: (users) {
                    final positions = positionsAsync.value ?? [];
                    final filteredEmployees = users.where((u) {
                      final posId = u['job_position_id'];
                      if (posId == null) {
                        return true; // Include if no position? Or exclude? Let's include.
                      }

                      final pos = positions.firstWhere(
                        (p) => p['id'] == posId,
                        orElse: () => {},
                      );
                      if (pos.isEmpty) return true;

                      final posName = (pos['name'] as String).toLowerCase();
                      return !posName.contains('chofer') &&
                          !posName.contains('soldador') &&
                          !posName.contains('instalador');
                    }).toList();

                    return DropdownButtonFormField<String>(
                      value: _selectedEmployeeId,
                      items:
                          filteredEmployees.map<DropdownMenuItem<String>>((e) {
                        return DropdownMenuItem<String>(
                          value: e['id'].toString(),
                          child: Text(
                              (e['full_name'] ?? e['name'])?.toString() ??
                                  'S/N',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedEmployeeId = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                      decoration: AppStyles.inputDecoration(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e'),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildDateField('Fecha', _fecha, (d) => setState(() => _fecha = d)),
            const SizedBox(height: 24),
            _buildTextField('Concepto / Periodo', _conceptoCtrl),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final field1 = Consumer(builder: (context, ref, _) {
                  final methodsAsync = ref.watch(paymentMethodsListProvider);
                  return methodsAsync.when(
                    data: (methods) {
                      if (_selectedFormaPago != null &&
                          !methods.any((m) => m.name == _selectedFormaPago)) {
                        _selectedFormaPago = null;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Forma de Pago',
                              style: AppStyles.labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedFormaPago,
                            items: methods
                                .map((m) => DropdownMenuItem(
                                      value: m.name,
                                      child: Text(m.name,
                                          style: const TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFormaPago = val;
                              });
                            },
                            decoration: AppStyles.inputDecoration(),
                            hint: const Text('Seleccionar'),
                            icon: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ],
                      );
                    },
                    loading: () => const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Forma de Pago', style: AppStyles.labelStyle),
                        SizedBox(height: 8),
                        CircularProgressIndicator(),
                      ],
                    ),
                    error: (e, s) => const Text('Error cargando métodos'),
                  );
                });
                final field2 = _buildTextField('Nro Referencia', _chequeCtrl);

                if (isMobile) {
                  return Column(
                    children: [
                      field1,
                      const SizedBox(height: 24),
                      field2,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: field1),
                    const SizedBox(width: 16),
                    Expanded(child: field2),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final field1 = _buildTextField('Días', _diasCtrl,
                    keyboardType: TextInputType.number);
                final field2 = _buildTextField('Monto', _montoCtrl,
                    required: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixText: '\$ ');

                if (isMobile) {
                  return Column(
                    children: [
                      field1,
                      const SizedBox(height: 24),
                      field2,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: field1),
                    const SizedBox(width: 16),
                    Expanded(child: field2),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildTextField('Notas', _notasCtrl, maxLines: 2),
            const SizedBox(height: 40),
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
                    : const Text('Guardar Pago'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final newItem = NominaPagoDiario(
          id: widget.item?.id ?? '',
          idEmpleado: _selectedEmployeeId!,
          fecha: _fecha,
          conceptoPeriodo: _conceptoCtrl.text,
          nroCheque: _chequeCtrl.text,
          dias: double.tryParse(_diasCtrl.text),
          formaPago: _selectedFormaPago,
          monto: double.tryParse(_montoCtrl.text),
          notas: _notasCtrl.text,
        );

        if (widget.item == null) {
          await ref.read(payrollRepositoryProvider).createPagoDiario(newItem);
        } else {
          await ref
              .read(payrollRepositoryProvider)
              .updatePagoDiario(widget.item!.id, newItem);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
