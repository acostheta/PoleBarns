import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../widgets/payments_dialog.dart';

class DestajoSoldadoresScreen extends ConsumerStatefulWidget {
  const DestajoSoldadoresScreen({super.key});

  @override
  ConsumerState<DestajoSoldadoresScreen> createState() =>
      _DestajoSoldadoresScreenState();
}

class _DestajoSoldadoresScreenState
    extends ConsumerState<DestajoSoldadoresScreen> {
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
                labelText: 'Buscar por producto o empleado...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NominaDestajoSoldador>>(
              stream: repo.getSoldadoresStream(),
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

                      final items = snapshot.data!.where((item) {
                        final empName =
                            empMap[item.idEmpleado]?.toLowerCase() ?? '';
                        final product = item.trussProducto?.toLowerCase() ?? '';
                        return empName.contains(_searchQuery) ||
                            product.contains(_searchQuery);
                      }).toList();

                      if (items.isEmpty)
                        return const Center(child: Text('No hay registros.'));

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final total = item.cantidad != null &&
                                  item.montoUnitario != null
                              ? item.cantidad! * item.montoUnitario!
                              : 0.0;
                          final saldo = total - (item.pagoParcial ?? 0);
                          final empName =
                              empMap[item.idEmpleado] ?? 'Desconocido';

                          return Card(
                            child: ListTile(
                              title: Text(
                                  'Producto: ${item.trussProducto} (Qty: ${item.cantidad})'),
                              subtitle: Text(
                                  'Empleado: $empName\nTotal: \$$total | Pagado: \$${item.pagoParcial}\nSaldo: \$$saldo'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.payments,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _showPaymentsDialog(context, item),
                                    tooltip: 'Ver/Agregar Pagos',
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
                                        repo.deleteSoldador(item.id),
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

  void _showEditDialog(BuildContext context, NominaDestajoSoldador? item) {
    showDialog(
      context: context,
      builder: (context) => _SoldadorDialog(item: item),
    );
  }

  void _showPaymentsDialog(BuildContext context, NominaDestajoSoldador item) {
    showDialog(
      context: context,
      builder: (context) =>
          PaymentsDialog(soldadorId: item.id, type: 'Soldadura'),
    );
  }
}

class _SoldadorDialog extends ConsumerStatefulWidget {
  final NominaDestajoSoldador? item;
  const _SoldadorDialog({this.item});

  @override
  ConsumerState<_SoldadorDialog> createState() => _SoldadorDialogState();
}

class _SoldadorDialogState extends ConsumerState<_SoldadorDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _trussCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notasCtrl;
  DateTime _fecha = DateTime.now();

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
    if (widget.item != null) _fecha = widget.item!.fecha;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(payrollRepositoryProvider);

    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo Soldadura' : 'Editar Soldadura'),
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
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.getRawMaterialsStream(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: list.any((e) => e['name'] == _trussCtrl.text)
                        ? _trussCtrl.text
                        : (widget.item?.trussProducto),
                    decoration:
                        const InputDecoration(labelText: 'Truss (Producto) *'),
                    items: list
                        .map((e) => DropdownMenuItem(
                            value: e['name'].toString(),
                            child: Text(e['name'] ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _trussCtrl.text = v ?? ''),
                    validator: (v) => v == null ? 'Requerido' : null,
                  );
                },
              ),
              TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: _priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Monto Unitario'),
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
              final newItem = NominaDestajoSoldador(
                id: widget.item?.id ?? '',
                idEmpleado: _selectedEmployeeId!,
                fecha: _fecha,
                trussProducto: _trussCtrl.text,
                cantidad: double.tryParse(_qtyCtrl.text),
                montoUnitario: double.tryParse(_priceCtrl.text),
                notas: _notasCtrl.text,
              );
              if (widget.item == null) {
                await ref
                    .read(payrollRepositoryProvider)
                    .createSoldador(newItem);
              } else {
                await ref
                    .read(payrollRepositoryProvider)
                    .updateSoldador(widget.item!.id, newItem);
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
