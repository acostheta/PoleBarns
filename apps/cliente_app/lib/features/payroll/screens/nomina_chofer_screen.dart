import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';

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
                              e['full_name']?.toString() ?? 'S/N'
                      };

                      final items = snapshot.data!.where((item) {
                        final empName =
                            empMap[item.idEmpleado]?.toLowerCase() ?? '';
                        final tasks = item.tareas?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery) ||
                            tasks.contains(_searchQuery);
                      }).toList();

                      if (items.isEmpty) {
                        return const Center(child: Text('No hay registros.'));
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final total =
                              (item.horas ?? 0) * (item.ratePorHora ?? 0);
                          final empName =
                              empMap[item.idEmpleado] ?? 'Desconocido';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              title: Text('Tareas: ${item.tareas}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    'Empleado: $empName\nFecha: ${DateFormat('MM/dd/yyyy').format(item.fecha)}\nHoras: ${item.horas} x \$${item.ratePorHora} = \$$total'),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(NominaChofer item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
            '¿Está seguro de que desea eliminar este registro de chofer?'),
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
      await ref.read(payrollRepositoryProvider).deleteChofer(item.id);
    }
  }

  void _showEditDialog(BuildContext context, NominaChofer? item) {
    showDialog(
      context: context,
      builder: (context) => _ChoferDialog(item: item),
    );
  }
}

class _ChoferDialog extends ConsumerStatefulWidget {
  final NominaChofer? item;
  const _ChoferDialog({this.item});

  @override
  ConsumerState<_ChoferDialog> createState() => _ChoferDialogState();
}

class _ChoferDialogState extends ConsumerState<_ChoferDialog> {
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
                    Text(widget.item == null ? 'Nuevo Chofer' : 'Editar Chofer',
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
                _buildDateField(
                    'Fecha', _fecha, (d) => setState(() => _fecha = d)),
                const SizedBox(height: 24),
                _buildTextField('Tareas', _tareasCtrl),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Horas', _horasCtrl,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField('Rate p/h', _rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
