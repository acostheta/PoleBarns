import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../widgets/payments_dialog.dart';

class NominaInstalacionScreen extends ConsumerStatefulWidget {
  const NominaInstalacionScreen({super.key});

  @override
  ConsumerState<NominaInstalacionScreen> createState() =>
      _NominaInstalacionScreenState();
}

class _NominaInstalacionScreenState
    extends ConsumerState<NominaInstalacionScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        backgroundColor: AppStyles.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            child: StreamBuilder<List<NominaInstalacion>>(
              stream: repo.getInstalacionStream(),
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

                      return items.isEmpty
                          ? const Center(child: Text('No hay registros.'))
                          : Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1200),
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
                                              dividerColor:
                                                  Colors.grey.shade200,
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
                                                DataColumn(
                                                    label: Text('EMPLEADO')),
                                                DataColumn(
                                                    label: Text('PAGO P.')),
                                                DataColumn(
                                                    label: Text('SALDO')),
                                                DataColumn(
                                                    label: Text('CERRADO')),
                                                DataColumn(
                                                    label: Text('ACCIONES')),
                                              ],
                                              rows: items.map((item) {
                                                final empName =
                                                    empMap[item.idEmpleado] ??
                                                        'Desconocido';
                                                return DataRow(
                                                  onSelectChanged: (_) {
                                                    _showPaymentsDialog(
                                                        context, item);
                                                  },
                                                  cells: [
                                                    DataCell(Text(empName,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                    DataCell(Text(
                                                        NumberFormat
                                                                .simpleCurrency()
                                                            .format(
                                                                item.pagoProyecto ??
                                                                    0),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.green))),
                                                    DataCell(Text(
                                                      NumberFormat
                                                              .simpleCurrency()
                                                          .format(
                                                              item.saldo ?? 0),
                                                      style: TextStyle(
                                                          color: (item.saldo ??
                                                                      0) >
                                                                  0
                                                              ? Colors.red
                                                              : Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )),
                                                    DataCell(Icon(
                                                        item.proyectoCerrado
                                                            ? Icons.check_circle
                                                            : Icons
                                                                .circle_outlined,
                                                        color:
                                                            item.proyectoCerrado
                                                                ? Colors.green
                                                                : Colors.grey,
                                                        size: 20)),
                                                    DataCell(Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .payments_outlined,
                                                              color:
                                                                  Colors.green,
                                                              size: 20),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () =>
                                                              _showPaymentsDialog(
                                                                  context,
                                                                  item),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              color:
                                                                  Colors.blue,
                                                              size: 20),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () =>
                                                              _showEditDialog(
                                                                  context,
                                                                  item),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: Colors.red,
                                                              size: 20),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                          onPressed: () =>
                                                              _confirmDelete(
                                                                  item),
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

  void _confirmDelete(NominaInstalacion item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
            '¿Está seguro de que desea eliminar este registro de instalación?'),
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
      await ref.read(payrollRepositoryProvider).deleteInstalacion(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaInstalacion? item) {
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
                  Text(
                      item == null ? 'Nueva Instalación' : 'Editar Instalación',
                      style: AppStyles.dialogTitleStyle),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: InstalacionForm(item: item)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaInstalacion item) {
    showDialog(
      context: context,
      builder: (context) =>
          PaymentsDialog(instalacionId: item.id, type: 'Instalación'),
    );
  }
}

class InstalacionForm extends ConsumerStatefulWidget {
  final NominaInstalacion? item;
  const InstalacionForm({super.key, this.item});

  @override
  ConsumerState<InstalacionForm> createState() => _InstalacionFormState();
}

class _InstalacionFormState extends ConsumerState<InstalacionForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _idProyectoCtrl;
  late TextEditingController _pagoCtrl;
  late TextEditingController _discountCtrl;
  bool _cerrado = false;
  DateTime? _fechaCulminacion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.item?.idEmpleado;
    _idProyectoCtrl =
        TextEditingController(text: widget.item?.idProyecto ?? '');
    _pagoCtrl = TextEditingController(
        text: widget.item?.pagoProyecto?.toString() ?? '');
    _discountCtrl =
        TextEditingController(text: widget.item?.descuentos?.toString() ?? '');
    _cerrado = widget.item?.proyectoCerrado ?? false;
    _fechaCulminacion = widget.item?.fechaCulminacion;
  }

  @override
  void dispose() {
    _idProyectoCtrl.dispose();
    _pagoCtrl.dispose();
    _discountCtrl.dispose();
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
            const SizedBox(height: 24),
            _buildDateField(
                'Fecha Culminación (Opcional)',
                _fechaCulminacion ?? DateTime.now(),
                (d) => setState(() => _fechaCulminacion = d)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildTextField('Pago Proyecto', _pagoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixText: '\$ ')),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField('Descuentos', _discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixText: '\$ ')),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text('Proyecto Cerrado', style: AppStyles.labelStyle),
                  const Spacer(),
                  Switch(
                    value: _cerrado,
                    activeColor: AppStyles.primaryOrange,
                    onChanged: (v) => setState(() => _cerrado = v),
                  ),
                ],
              ),
            ),
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
        final newItem = NominaInstalacion(
          id: widget.item?.id ?? '',
          idEmpleado: _selectedEmployeeId!,
          idProyecto: '',
          fechaCulminacion: _fechaCulminacion,
          pagoProyecto: double.tryParse(_pagoCtrl.text),
          proyectoCerrado: _cerrado,
          descuentos: double.tryParse(_discountCtrl.text),
        );
        if (widget.item == null) {
          await ref.read(payrollRepositoryProvider).createInstalacion(newItem);
        } else {
          await ref
              .read(payrollRepositoryProvider)
              .updateInstalacion(widget.item!.id, newItem);
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
