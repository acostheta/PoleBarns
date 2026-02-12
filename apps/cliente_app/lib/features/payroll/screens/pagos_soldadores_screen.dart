import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../widgets/payments_dialog.dart';
import '../widgets/pagos_soldadores_form_dialog.dart';
import '../../settings/repositories/settings_repository.dart';

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
                                              _showPaymentsDialog(
                                                  context, item);
                                            },
                                            cells: [
                                              DataCell(Text(
                                                  DateFormat('dd/MM/yyyy')
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
            '¿Está seguro de que desea eliminar este registro de pago a soldador?'),
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
      await ref.read(payrollRepositoryProvider).deleteSoldador(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaSoldador? item) {
    showDialog(
      context: context,
      builder: (context) => PagosSoldadoresFormDialog(item: item),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaSoldador item) {
    showDialog(
      context: context,
      builder: (context) =>
          PaymentsDialog(soldadorId: item.id, type: 'Soldadura'),
    );
  }
}

class SoldadorForm extends ConsumerStatefulWidget {
  final NominaSoldador? item;
  const SoldadorForm({super.key, this.item});

  @override
  ConsumerState<SoldadorForm> createState() => _SoldadorFormState();
}

class _SoldadorFormState extends ConsumerState<SoldadorForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _trussCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _notasCtrl;
  String? _selectedFormaPago;
  DateTime _fecha = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.item?.idEmpleado;
    _trussCtrl = TextEditingController(text: widget.item?.trussProducto ?? '');
    _qtyCtrl =
        TextEditingController(text: widget.item?.cantidad?.toString() ?? '');
    _priceCtrl = TextEditingController(
        text: widget.item?.montoUnitario?.toString() ?? '');
    _notasCtrl = TextEditingController(text: widget.item?.notas ?? '');
    _selectedFormaPago = widget.item?.formaPago;

    double initialTotal = 0;
    if (widget.item?.total != null) {
      initialTotal = widget.item!.total!;
    } else {
      final q = double.tryParse(_qtyCtrl.text) ?? 0;
      final p = double.tryParse(_priceCtrl.text) ?? 0;
      initialTotal = q * p;
    }
    _totalCtrl = TextEditingController(text: initialTotal.toStringAsFixed(2));

    if (widget.item != null) _fecha = widget.item!.fecha;

    _qtyCtrl.addListener(_updateTotal);
    _priceCtrl.addListener(_updateTotal);
  }

  void _updateTotal() {
    final q = double.tryParse(_qtyCtrl.text) ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    final t = q * p;
    _totalCtrl.text = t.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_updateTotal);
    _priceCtrl.removeListener(_updateTotal);
    _trussCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _totalCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empleado', style: AppStyles.labelStyle),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.getEmployeesStream(),
              builder: (context, snapshot) {
                final employees = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  items: employees.map<DropdownMenuItem<String>>((e) {
                    return DropdownMenuItem<String>(
                      value: e['id'].toString(),
                      child: Text(
                          (e['full_name'] ?? e['name'])?.toString() ?? 'S/N',
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedEmployeeId = v),
                  validator: (v) => v == null ? 'Requerido' : null,
                  decoration: AppStyles.inputDecoration(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildDateField('Fecha', _fecha, (d) => setState(() => _fecha = d)),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildTextField('Cantidad', _qtyCtrl,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField('Monto Unitario', _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixText: '\$ ')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
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
                                            style:
                                                const TextStyle(fontSize: 14)),
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
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error'),
                    );
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField('Monto Total', _totalCtrl,
                        keyboardType: TextInputType.number,
                        readOnly: true, // Auto-calculated
                        prefixText: '\$ ')),
              ],
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
        final newItem = NominaSoldador(
          id: widget.item?.id ?? '',
          idEmpleado: _selectedEmployeeId!,
          fecha: _fecha,
          trussProducto: '',
          cantidad: double.tryParse(_qtyCtrl.text),
          montoUnitario: double.tryParse(_priceCtrl.text),
          formaPago: _selectedFormaPago,
          total: double.tryParse(_totalCtrl.text),
          notas: _notasCtrl.text,
        );
        if (widget.item == null) {
          await ref.read(payrollRepositoryProvider).createSoldador(newItem);
        } else {
          await ref
              .read(payrollRepositoryProvider)
              .updateSoldador(widget.item!.id, newItem);
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
      bool readOnly = false,
      int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
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
