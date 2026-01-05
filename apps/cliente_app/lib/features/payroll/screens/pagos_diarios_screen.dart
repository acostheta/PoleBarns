import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';

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
                labelText: 'Buscar por concepto o empleado...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaPagoDiario>>(
              stream: repository.getPagosDiariosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: repository.getEmployeesStream(),
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
                        final concept =
                            item.conceptoPeriodo?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery) ||
                            concept.contains(_searchQuery);
                      }).toList();

                      if (items.isEmpty)
                        return const Center(child: Text('No hay registros.'));

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final empName =
                              empMap[item.idEmpleado] ?? 'Desconocido';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                  'Pago: \$${item.monto ?? 0} - ${item.fecha.toLocal().toString().split(' ')[0]}'),
                              subtitle: Text(
                                  'Concepto: ${item.conceptoPeriodo ?? ''}\nEmpleado: $empName'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item),
                              ),
                              onTap: () {
                                _showEditDialog(context, item);
                              },
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

  Future<void> _deleteItem(NominaPagoDiario item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
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
      builder: (context) => _PagoDiarioDialog(item: item),
    );
  }
}

class _PagoDiarioDialog extends ConsumerStatefulWidget {
  final NominaPagoDiario? item;
  const _PagoDiarioDialog({this.item});

  @override
  ConsumerState<_PagoDiarioDialog> createState() => _PagoDiarioDialogState();
}

class _PagoDiarioDialogState extends ConsumerState<_PagoDiarioDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _conceptoCtrl;
  late TextEditingController _montoCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _chequeCtrl;
  late TextEditingController _diasCtrl;
  late TextEditingController _formaPagoCtrl;
  DateTime _fecha = DateTime.now();

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
    _formaPagoCtrl = TextEditingController(text: widget.item?.formaPago ?? '');
    if (widget.item != null) _fecha = widget.item!.fecha;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);

    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo Pago Diario' : 'Editar Pago'),
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
                title:
                    Text('Fecha: ${_fecha.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _fecha = d);
                },
              ),
              TextFormField(
                controller: _conceptoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Concepto/Periodo'),
              ),
              TextFormField(
                controller: _chequeCtrl,
                decoration: const InputDecoration(labelText: 'Nro Cheque'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diasCtrl,
                      decoration: const InputDecoration(labelText: 'Días'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _montoCtrl,
                      decoration: const InputDecoration(labelText: 'Monto *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _formaPagoCtrl,
                decoration: const InputDecoration(labelText: 'Forma de Pago'),
              ),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2,
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
              final newItem = NominaPagoDiario(
                id: widget.item?.id ?? '',
                idEmpleado: _selectedEmployeeId!,
                fecha: _fecha,
                conceptoPeriodo: _conceptoCtrl.text,
                nroCheque: _chequeCtrl.text,
                dias: double.tryParse(_diasCtrl.text),
                formaPago: _formaPagoCtrl.text,
                monto: double.tryParse(_montoCtrl.text),
                notas: _notasCtrl.text,
              );

              if (widget.item == null) {
                await ref
                    .read(payrollRepositoryProvider)
                    .createPagoDiario(newItem);
              } else {
                await ref
                    .read(payrollRepositoryProvider)
                    .updatePagoDiario(widget.item!.id, newItem);
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
