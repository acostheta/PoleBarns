import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por proyecto o empleado...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaInstalacion>>(
              stream: repo.getInstalacionStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // Get employees for name lookup
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
                                    p['name']?.toString() ?? 'S/P'
                            };

                            final items = snapshot.data!.where((item) {
                              final empName =
                                  empMap[item.idEmpleado]?.toLowerCase() ?? '';
                              final projName =
                                  projMap[item.idProyecto]?.toLowerCase() ?? '';
                              return empName.contains(_searchQuery) ||
                                  projName.contains(_searchQuery);
                            }).toList();

                            if (items.isEmpty)
                              return const Center(
                                  child: Text('No hay registros.'));

                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final empName =
                                    empMap[item.idEmpleado] ?? 'Desconocido';
                                final projName = projMap[item.idProyecto] ??
                                    'Proyecto Desconocido';

                                return Card(
                                  child: ListTile(
                                    title: Text('Proyecto: $projName'),
                                    subtitle: Text(
                                        'Empleado: $empName\nPago: \$${item.pagoProyecto} | Saldo: \$${item.saldo}\nCerrado: ${item.proyectoCerrado ? 'Sí' : 'No'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.payments,
                                              color: Colors.green),
                                          onPressed: () => _showPaymentsDialog(
                                              context, item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _showEditDialog(context, item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              repo.deleteInstalacion(item.id),
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

    return AlertDialog(
      title: Text(
          widget.item == null ? 'Nueva Instalación' : 'Editar Instalación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.getEmployeesStream(),
                builder: (context, snapshot) {
                  final employees = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    decoration: const InputDecoration(labelText: 'Empleado *'),
                    items: employees.map((e) {
                      return DropdownMenuItem<String>(
                        value: e['id'].toString(),
                        child: Text(e['full_name'] ?? 'S/N'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedEmployeeId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  );
                },
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.getProjectsStream(),
                builder: (context, snapshot) {
                  final projects = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _idProyectoCtrl.text.isEmpty
                        ? null
                        : _idProyectoCtrl.text,
                    decoration: const InputDecoration(labelText: 'Proyecto *'),
                    items: projects.map((e) {
                      return DropdownMenuItem<String>(
                        value: e['id'].toString(),
                        child: Text(e['name'] ?? 'S/N'),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _idProyectoCtrl.text = v ?? ''),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  );
                },
              ),
              ListTile(
                title: Text(_fechaCulminacion == null
                    ? 'Fecha Culminación'
                    : _fechaCulminacion!.toIso8601String().split('T')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _fechaCulminacion ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => _fechaCulminacion = d);
                },
              ),
              TextFormField(
                  controller: _pagoCtrl,
                  decoration: const InputDecoration(labelText: 'Pago Proyecto'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: _discountCtrl,
                  decoration: const InputDecoration(labelText: 'Descuentos'),
                  keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Proyecto Cerrado'),
                value: _cerrado,
                onChanged: (v) => setState(() => _cerrado = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
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
                await ref
                    .read(payrollRepositoryProvider)
                    .createInstalacion(newItem);
              } else {
                await ref
                    .read(payrollRepositoryProvider)
                    .updateInstalacion(widget.item!.id, newItem);
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
