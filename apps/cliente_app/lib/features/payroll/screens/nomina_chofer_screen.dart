import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por tareas o empleado...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaChofer>>(
              stream: repo.getChoferStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

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

                      if (items.isEmpty)
                        return const Center(child: Text('No hay registros.'));

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final total =
                              (item.horas ?? 0) * (item.ratePorHora ?? 0);
                          final empName =
                              empMap[item.idEmpleado] ?? 'Desconocido';
                          return Card(
                            child: ListTile(
                              title: Text('Tareas: ${item.tareas}'),
                              subtitle: Text(
                                  'Empleado: $empName\nFecha: ${item.fecha.toIso8601String().split('T')[0]}\nHoras: ${item.horas} x \$${item.ratePorHora} = \$$total'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showEditDialog(context, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => repo.deleteChofer(item.id),
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

    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo Chofer' : 'Editar Chofer'),
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
              ListTile(
                title: Text('Fecha: ${_fecha.toIso8601String().split('T')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => _fecha = d);
                },
              ),
              TextFormField(
                  controller: _tareasCtrl,
                  decoration: const InputDecoration(labelText: 'Tareas')),
              TextFormField(
                  controller: _horasCtrl,
                  decoration: const InputDecoration(labelText: 'Horas'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: _rateCtrl,
                  decoration: const InputDecoration(labelText: 'Rate p/h'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas')),
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
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
