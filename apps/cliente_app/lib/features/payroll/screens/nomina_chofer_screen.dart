import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../../../config/ui_helpers.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import 'package:users/users.dart';
import '../widgets/payments_dialog.dart';
import '../providers/payroll_summary_provider.dart';
import 'chofer_detail_screen.dart';

class NominaChoferScreen extends ConsumerStatefulWidget {
  const NominaChoferScreen({super.key});

  @override
  ConsumerState<NominaChoferScreen> createState() => _NominaChoferScreenState();
}

class _NominaChoferScreenState extends ConsumerState<NominaChoferScreen> {
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
              decoration: AppStyles.inputDecoration(
                      hintText: 'Buscar por tareas o empleado...')
                  .copyWith(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaChofer>>(
              stream: repo.getChoferStream(),
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
                        final tasks = item.tareas?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery) ||
                            tasks.contains(_searchQuery);
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
                                          DataColumn(label: Text('TAREAS')),
                                          DataColumn(label: Text('HORAS')),
                                          DataColumn(label: Text('RATE/H')),
                                          DataColumn(label: Text('TOTAL')),
                                          DataColumn(label: Text('PAGADO')),
                                          DataColumn(label: Text('SALDO')),
                                          DataColumn(label: Text('ACCIONES')),
                                        ],
                                        rows: items.map((item) {
                                          final total = (item.horas ?? 0) *
                                              (item.ratePorHora ?? 0);
                                          final empName =
                                              empMap[item.idEmpleado] ??
                                                  'Desconocido';

                                          return DataRow(
                                            onSelectChanged: (_) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChoferDetailScreen(
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
                                                        maxWidth: 200),
                                                child: Text(item.tareas ?? '-',
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              )),
                                              DataCell(Text(
                                                  item.horas?.toString() ??
                                                      '-')),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(
                                                          item.ratePorHora ??
                                                              0))),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(total),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green))),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(
                                                          item.pagoParcial ??
                                                              0),
                                                  style: const TextStyle(
                                                      color: Colors.blue))),
                                              DataCell(Text(
                                                  NumberFormat.simpleCurrency()
                                                      .format(total -
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
                                                  const SizedBox(width: 12),
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

  void _deleteItem(NominaChofer item) async {
    final confirm = await AppBottomSheet.showConfirm(
      context: context,
      title: 'Eliminar Registro',
      message: '¿Está seguro de que desea eliminar este registro de chofer?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (confirm == true) {
      await ref.read(payrollRepositoryProvider).deleteChofer(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaChofer? item) {
    AppBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item == null ? 'Nuevo Chofer' : 'Editar Chofer',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF173124))),
            const SizedBox(height: 32),
            Flexible(child: ChoferForm(item: item)),
          ],
        ),
      ),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaChofer item) {
    final total = (item.horas ?? 0.0) * (item.ratePorHora ?? 0.0);
    final balance = total - (item.pagoParcial ?? 0.0);
    AppBottomSheet.show(
      context: context,
      child: PaymentsDialog(
        choferId: item.id,
        type: 'Chofer',
        initialAmount: balance > 0 ? balance : null,
      ),
    );
  }
}

class ChoferForm extends ConsumerStatefulWidget {
  final NominaChofer? item;
  const ChoferForm({super.key, this.item});

  @override
  ConsumerState<ChoferForm> createState() => _ChoferFormState();
}

class _ChoferFormState extends ConsumerState<ChoferForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _tareasCtrl;
  late TextEditingController _horasCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _notasCtrl;
  DateTime _fecha = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.item?.idEmpleado;
    _tareasCtrl = TextEditingController(text: widget.item?.tareas ?? '');
    _horasCtrl =
        TextEditingController(text: widget.item?.horas?.toString() ?? '');
    _rateCtrl =
        TextEditingController(text: widget.item?.ratePorHora?.toString() ?? '');
    _notasCtrl = TextEditingController(text: widget.item?.notas ?? '');
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
                      if (posId == null) return false;

                      final pos = positions.firstWhere(
                        (p) => p['id'] == posId,
                        orElse: () => {},
                      );
                      if (pos.isEmpty) return false;

                      final posName = (pos['name'] as String).toLowerCase();
                      return posName.contains('chofer');
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
            _buildTextField('Tareas', _tareasCtrl),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final field1 = _buildTextField('Horas', _horasCtrl,
                    keyboardType: TextInputType.number);
                final field2 = _buildTextField('Rate p/h', _rateCtrl,
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
                    : const Text('Guardar Registro'),
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
        final newItem = NominaChofer(
          id: widget.item?.id ?? '',
          idEmpleado: _selectedEmployeeId!,
          fecha: _fecha,
          tareas: _tareasCtrl.text,
          horas: double.tryParse(_horasCtrl.text),
          ratePorHora: double.tryParse(_rateCtrl.text),
          notas: _notasCtrl.text,
        );
        if (widget.item == null) {
          await ref.read(payrollRepositoryProvider).createChofer(newItem);
        } else {
          await ref
              .read(payrollRepositoryProvider)
              .updateChofer(widget.item!.id, newItem);
        }
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
          decoration:
              AppStyles.inputDecoration().copyWith(prefixText: prefixText),
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
