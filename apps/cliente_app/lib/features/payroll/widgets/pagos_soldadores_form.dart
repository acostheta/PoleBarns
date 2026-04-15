import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import 'package:users/users.dart';
import '../models/payroll_models.dart';
import '../repositories/payroll_repository.dart';
import '../../settings/repositories/settings_repository.dart';

class PagosSoldadoresForm extends ConsumerStatefulWidget {
  final NominaSoldador? item;
  final VoidCallback? onSaved;

  const PagosSoldadoresForm({super.key, this.item, this.onSaved});

  @override
  ConsumerState<PagosSoldadoresForm> createState() =>
      _PagosSoldadoresFormState();
}

class _PagosSoldadoresFormState extends ConsumerState<PagosSoldadoresForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController _notasCtrl;
  String? _selectedFormaPago;
  DateTime _fecha = DateTime.now();
  bool _isLoading = false;

  // Table data for trusses
  final List<TrussLineItem> _trussItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.item?.idEmpleado;
    _notasCtrl = TextEditingController(text: widget.item?.notas ?? '');
    _selectedFormaPago = widget.item?.formaPago;

    if (widget.item != null) {
      _fecha = widget.item!.fecha;
      _loadSpecificTrusses();
    }
  }

  Future<void> _loadSpecificTrusses() async {
    if (widget.item != null) {
      try {
        final trusses = await ref
            .read(payrollRepositoryProvider)
            .getSpecificTrussesBySoldador(widget.item!.id);
        if (mounted) {
          setState(() {
            _trussItems.clear();
            for (var st in trusses) {
              _trussItems.add(TrussLineItem(
                trussId: st.trussId,
                trussName: st.trussName,
                quantity: st.quantity,
                unitPrice: st.unitPrice,
              ));
            }
            _recalculateTotal();
          });
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    double total = 0;
    for (var item in _trussItems) {
      total += item.quantity * item.unitPrice;
    }
    setState(() => _totalAmount = total);
  }

  void _addTrussRow() {
    setState(() {
      _trussItems.add(TrussLineItem(
        trussId: '',
        trussName: '',
        quantity: 0,
        unitPrice: 0,
      ));
    });
  }

  void _removeTrussRow(int index) {
    setState(() {
      _trussItems.removeAt(index);
      _recalculateTotal();
    });
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
                      return posName.contains('soldador');
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
                      isExpanded: true,
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
            // Trusses Table Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Trabajos Realizados (Trusses/Lean To)',
                      style: AppStyles.labelStyle),
                ),
                ElevatedButton.icon(
                  onPressed: _addTrussRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryOrange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrussesTable(),
            const SizedBox(height: 16),
            // Total Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto Total',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.simpleCurrency().format(_totalAmount),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryOrange),
                  ),
                ],
              ),
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
                              isExpanded: true,
                            ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error'),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField('Notas', _notasCtrl, maxLines: 3),
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

  Widget _buildTrussesTable() {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return productsAsync.when(
      data: (products) {
        if (_trussItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No hay trabajos agregados. Presione "Agregar".',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width > 600
                      ? MediaQuery.of(context).size.width - 200
                      : 600),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FixedColumnWidth(40),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                ),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Producto',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Cant.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Precio',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  SizedBox(width: 40),
                ],
              ),
              // Data rows
              ..._trussItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return TableRow(
                  children: [
                    // Dropdown for Product selection
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: DropdownButtonFormField<String>(
                        value: item.trussId.isEmpty ||
                                !products.any((p) => p.id == item.trussId)
                            ? null
                            : item.trussId,
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name,
                                style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (productId) {
                          if (productId == null) return;
                          final selectedProduct =
                              products.firstWhere((p) => p.id == productId);
                          setState(() {
                            _trussItems[index] = TrussLineItem(
                              trussId: selectedProduct.id,
                              trussName: selectedProduct.name,
                              quantity: item.quantity,
                              unitPrice: selectedProduct.cost,
                            );
                            _recalculateTotal();
                          });
                        },
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        isDense: true,
                        isExpanded: true,
                      ),
                    ),
                    // Quantity
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        initialValue: item.quantity.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _trussItems[index] = TrussLineItem(
                              trussId: item.trussId,
                              trussName: item.trussName,
                              quantity: double.tryParse(value) ?? 0,
                              unitPrice: item.unitPrice,
                            );
                            _recalculateTotal();
                          });
                        },
                      ),
                    ),
                    // Unit Price (readonly)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        NumberFormat.simpleCurrency().format(item.unitPrice),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Total (calculated)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        NumberFormat.simpleCurrency()
                            .format(item.quantity * item.unitPrice),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () => _removeTrussRow(index),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              }),
            ],
          ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error cargando productos: $e'),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_trussItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debe agregar al menos un trabajo realizado')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final newItem = NominaSoldador(
          id: widget.item?.id ?? '',
          idEmpleado: _selectedEmployeeId!,
          fecha: _fecha,
          trussProducto: '',
          cantidad: _totalAmount,
          montoUnitario: 1,
          formaPago: _selectedFormaPago,
          total: _totalAmount,
          notas: _notasCtrl.text,
        );

        String soldadorId;
        if (widget.item == null) {
          soldadorId =
              await ref.read(payrollRepositoryProvider).createSoldador(newItem);

          // If a payment method is selected, record the initial payment
          if (_selectedFormaPago != null && _totalAmount > 0) {
            final payment = NominaPago(
              id: '',
              tipo: 'Soldadura',
              idNominaSoldadura: soldadorId,
              amount: _totalAmount,
              metodoPago: _selectedFormaPago,
              category: 'Pago Inicial',
              nota: 'Generado automáticamente al crear el registro',
              createdAt: DateTime.now(),
            );
            await ref.read(payrollRepositoryProvider).createPayment(payment);
          }
        } else {
          await ref
              .read(payrollRepositoryProvider)
              .updateSoldador(widget.item!.id, newItem);
          soldadorId = widget.item!.id;

          await ref
              .read(payrollRepositoryProvider)
              .deleteSpecificTrussesBySoldador(soldadorId);
        }

        final trussesData = _trussItems.map((item) {
          return {
            'truss_id': item.trussId,
            'truss_name': item.trussName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          };
        }).toList();

        await ref
            .read(payrollRepositoryProvider)
            .createSpecificTrusses(soldadorId, trussesData);

        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          if (mounted) {
            // Success!
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro guardado correctamente')),
            );
            Navigator.pop(context);
          }
        }
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
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: AppStyles.inputDecoration(),
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

class TrussLineItem {
  final String trussId;
  final String trussName;
  final double quantity;
  final double unitPrice;

  TrussLineItem({
    required this.trussId,
    required this.trussName,
    required this.quantity,
    required this.unitPrice,
  });
}
