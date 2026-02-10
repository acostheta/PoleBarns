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
              decoration: AppStyles.inputDecoration(
                      hintText: 'Buscar por proyecto o empleado...')
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
                              e['full_name']?.toString() ?? 'S/N'
                      };

                      return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: repo.getProjectsStream(),
                          builder: (context, projSnapshot) {
                            final projects = projSnapshot.data ?? [];
                            final projMap = {
                              for (var p in projects)
                                p['id'].toString():
                                    p['address']?.toString() ?? 'S/P'
                            };

                            final items = snapshot.data!.where((item) {
                              final empName =
                                  empMap[item.idEmpleado]?.toLowerCase() ?? '';
                              final projName =
                                  projMap[item.idProyecto]?.toLowerCase() ?? '';
                              return empName.contains(_searchQuery) ||
                                  projName.contains(_searchQuery);
                            }).toList();

                            if (items.isEmpty) {
                              return const Center(
                                  child: Text('No hay registros.'));
                            }

                            return ListView.builder(
                              itemCount: items.length,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final empName =
                                    empMap[item.idEmpleado] ?? 'Desconocido';
                                final projName = projMap[item.idProyecto] ??
                                    'Proyecto Desconocido';

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    title: Text('Proyecto: $projName',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                          'Empleado: $empName\nPago: \$${item.pagoProyecto} | Saldo: \$${item.saldo}\nCerrado: ${item.proyectoCerrado ? 'Sí' : 'No'}'),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.payments_outlined,
                                              color: Colors.green),
                                          onPressed: () => _showPaymentsDialog(
                                              context, item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _showEditDialog(context, item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          onPressed: () => _confirmDelete(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          });
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
      builder: (context) => _InstalacionDialog(item: item),
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

class _InstalacionDialog extends ConsumerStatefulWidget {
  final NominaInstalacion? item;
  const _InstalacionDialog({this.item});

  @override
  ConsumerState<_InstalacionDialog> createState() => _InstalacionDialogState();
}

class _InstalacionDialogState extends ConsumerState<_InstalacionDialog> {
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

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        widget.item == null
                            ? 'Nueva Instalación'
                            : 'Editar Instalación',
                        style: AppStyles.dialogTitleStyle),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 32),
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
                          child: Text(e['full_name'] ?? 'S/N',
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
                const Text('Proyecto', style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repo.getProjectsStream(),
                  builder: (context, snapshot) {
                    final projects = (snapshot.data ?? []).where((p) {
                      final status = p['estatus'];
                      final isPendingOrInProcess =
                          status == 'Pendiente' || status == 'En Proceso';
                      final isCurrentValue =
                          _idProyectoCtrl.text == p['id'].toString();
                      return isPendingOrInProcess || isCurrentValue;
                    }).toList();

                    return DropdownButtonFormField<String>(
                      value: _idProyectoCtrl.text.isEmpty
                          ? null
                          : _idProyectoCtrl.text,
                      items: projects.map<DropdownMenuItem<String>>((e) {
                        return DropdownMenuItem<String>(
                          value: e['id'].toString(),
                          child: Text(e['address'] ?? 'S/N',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _idProyectoCtrl.text = v ?? ''),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                      decoration: AppStyles.inputDecoration(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    );
                  },
                ),
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
                      const Text('Proyecto Cerrado',
                          style: AppStyles.labelStyle),
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
          idProyecto: _idProyectoCtrl.text,
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
