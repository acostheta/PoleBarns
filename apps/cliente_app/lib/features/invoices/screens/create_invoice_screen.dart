import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/app_styles.dart';
import '../../project_tracking/providers/project_providers.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../utils/invoice_pdf_generator.dart';
import '../../clients/repositories/client_repository.dart';
import '../../project_tracking/models/project_models.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final int? invoiceId;
  final String? clientId;

  const CreateInvoiceScreen(
      {super.key, this.projectId, this.invoiceId, this.clientId});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _addressController = TextEditingController();
  final _projectController = TextEditingController();
  final _notesController = TextEditingController(
      text:
          '''1. Prices are based on the approximate square footage detailed above. Any variations will be adjusted accordingly during the project's development or upon completion.
2. 50% of the invoice total is due upon delivery of the materials.
3. All materials used for this project are the property of J&P Pole Barns LLC. Any remaining or unused materials will remain with the company.
4. Any additional work requested by the client during the project will be documented, and corresponding budget adjustments will be provided.''');

  String? _selectedClientId;
  String _status = 'Pendiente';
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now().add(const Duration(days: 30));

  List<Map<String, dynamic>> _selectedItems = [];
  List<CatalogItemModel> _catalogItems = [];
  bool _isLoading = false;
  int? _nextInvoiceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _addressController.dispose();
    _projectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(invoiceServiceProvider);

      // Load Catalog
      _catalogItems = await service.getCatalogItems();

      if (widget.invoiceId != null) {
        await _loadExistingInvoice(widget.invoiceId!);
      } else {
        // Fetch next ID for new invoice pattern
        final invoices = await service.getInvoices();
        _nextInvoiceId = invoices.isNotEmpty ? (invoices.first.id + 1) : 1;

        if (widget.clientId != null) {
          _selectedClientId = widget.clientId;
          // Initial load for client data if provided
          await _updateClientData(_selectedClientId!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingInvoice(int id) async {
    final service = ref.read(invoiceServiceProvider);
    final invoice = await service.getInvoice(id);
    final products = await service.getRelatedProducts(id);

    setState(() {
      _projectController.text = invoice.projectName ?? '';
      _selectedClientId = invoice.idCliente;
      _addressController.text = invoice.address ?? '';
      _commentController.text = invoice.comentario ?? '';
      _notesController.text = invoice.notesForInvoice ?? _notesController.text;
      _selectedDate = invoice.date;

      _selectedDate = invoice.date;

      _status = invoice.status;
      _startDate = invoice.startDate;
      _endDate = invoice.endDate;

      _selectedItems = products.map((p) {
        return {
          'pole_barn_id': p.idPoleBarns,
          'sale_price': p.precioPorUnidad,
          'qty': p.cantidad,
          'tax': p.tax,
          'estatus': p.estatus,
          'PoleBarns': {'name': p.poleBarnName ?? 'Item'},
          'unit_cost': p.unitCost,
          'is_existing': true,
          'related_product_id': p.id,
        };
      }).toList();
    });
  }

  Future<void> _updateClientData(String clientId) async {
    try {
      final clientRepo = ref.read(clientRepositoryProvider);
      final client = await clientRepo.getClient(clientId);
      if (client != null) {
        setState(() {
          _addressController.text = client.direccion ?? '';
          final idToDisplay = widget.invoiceId ?? _nextInvoiceId ?? '#';
          _projectController.text = "$idToDisplay - ${client.nombre}";
        });
      }
    } catch (e) {
      debugPrint('Error loading client data: $e');
    }
  }

  void _addItemsFromCatalog() async {
    await showDialog(
      context: context,
      builder: (context) => _CatalogSelectionDialog(
        items: _catalogItems,
        onSelected: (selected) {
          setState(() {
            for (var item in selected) {
              _selectedItems.add({
                'pole_barn_id': item.id,
                'sale_price': item.salePrice,
                'unit_cost': item.cost,
                'qty': 1.0,
                'tax': 0.0,
                'estatus': 'Pendiente',
                'PoleBarns': {'name': item.name},
                'is_existing': false,
              });
            }
          });
        },
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(invoiceServiceProvider);
      final totalVenta = _selectedItems.fold<double>(0, (sum, item) {
        final qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
        final price = (item['sale_price'] as num?)?.toDouble() ?? 0.0;
        final tax = (item['tax'] as num?)?.toDouble() ?? 0.0;
        return sum + (qty * price * (1 + tax / 100));
      });

      final invoiceModel = InvoiceModel(
        id: widget.invoiceId ?? 0,
        idProyecto: null, // Decoupled
        projectName: _projectController.text,
        idCliente: _selectedClientId,
        address: _addressController.text,
        date: _selectedDate,
        totalVenta: totalVenta,
        comentario: _commentController.text,
        notesForInvoice: _notesController.text,
        createdAt: DateTime.now(),
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Prepare items for initial save or manual processing
      // Note: service.createInvoice handles inserting items.
      final productsToSave = _selectedItems.map((item) {
        return {
          'IdProyecto': null, // Decoupled
          'IdPoleBarns': item['pole_barn_id'],
          'Estatus': item['estatus'] ?? 'Pendiente',
          'Cantidad': item['qty'] ?? 1.0,
          'Precio por unidad': item['sale_price'] ?? 0.0,
          'Tax': item['tax'] ?? 0.0,
          'unit_cost': item['unit_cost'] ?? 0.0,
          if (item['is_existing'] == true) 'id': item['related_product_id'],
        };
      }).toList();

      if (widget.invoiceId != null) {
        await service.updateInvoice(invoiceModel);
        // Save items manuallly for update
        for (var p in productsToSave) {
          if (p.containsKey('id')) {
            await service.updateRelatedProduct(p['id'] as int, p);
          } else {
            p['IdInvoice'] = widget.invoiceId;
            await Supabase.instance.client
                .from('Related Products')
                .insert(p)
                .select()
                .single();
            // We could update state here with new ID but we are closing the screen
          }
        }
      } else {
        final newId = await service.createInvoice(invoiceModel, productsToSave);
        _sendInvoiceEmail(newId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Factura guardada')));
        Navigator.pop(context);
        ref.invalidate(invoicesStreamProvider);
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

  Future<void> _sendInvoiceEmail(int invoiceId) async {
    try {
      final service = ref.read(invoiceServiceProvider);
      final clientRepo = ref.read(clientRepositoryProvider);

      final fullInvoice = await service.getInvoice(invoiceId);
      final products = await service.getRelatedProducts(invoiceId);
      final client = await clientRepo.getClient(_selectedClientId!);

      if (client?.email == null || client!.email!.isEmpty) {
        debugPrint(
            'No se pudo enviar correo: El cliente no tiene email configurado.');
        return;
      }

      final pdfBytes = await InvoicePdfGenerator.getBytes(
        invoice: fullInvoice,
        products: products,
        payments: [],
      );

      await service.sendInvoiceByEmail(
        invoiceId: invoiceId,
        pdfBytes: pdfBytes,
        clientEmail: client.email!,
        clientName: client.nombre,
      );
    } catch (e) {
      debugPrint('Error al enviar factura por correo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            widget.invoiceId != null ? 'Editar Factura' : 'Crear Factura',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información del Proyecto'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child:
                              _buildTextField('Proyecto', _projectController)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildClientDropdown(clientsAsync)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Billing Address - Text Field Plain
                  const Text('Dirección de Facturación',
                      style: AppStyles.labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'Ingrese dirección',
                    ).copyWith(
                      prefixIcon: const Icon(Icons.place, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey, size: 20),
                        onPressed: () => _addressController.clear(),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Detalles de la Factura'),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateSelector(
                              'Fecha estimada de inicio de trabajos',
                              _startDate,
                              (d) => setState(() => _startDate = d))),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildDateSelector(
                              'Fecha estimada de culminación de trabajos',
                              _endDate,
                              (d) => setState(() => _endDate = d))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateSelector(
                              'Fecha de Facturación',
                              _selectedDate,
                              (d) => setState(() => _selectedDate = d))),
                      const SizedBox(width: 24),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text("Estatus", style: AppStyles.labelStyle),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: AppStyles.inputDecoration(),
                              items: [
                                'Pendiente',
                                'Pagado',
                                'Parcial',
                                'Cancelado'
                              ]
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ])),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Items'),
                      ElevatedButton.icon(
                        onPressed: _addItemsFromCatalog,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar del Catálogo'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildItemsTable(),

                  const SizedBox(height: 32),
                  _buildTextField('Comentarios', _commentController,
                      maxLines: 3),

                  const SizedBox(height: 24),
                  _buildTextField('Notes for Invoice', _notesController,
                      maxLines: 5),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveInvoice,
                      style: AppStyles.primaryButtonStyle,
                      child: Text(widget.invoiceId != null
                          ? 'Actualizar Factura'
                          : 'Crear Factura'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: AppStyles.dialogTitleStyle.copyWith(fontSize: 18));
  }

  Widget _buildClientDropdown(AsyncValue clientsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente', style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        clientsAsync.when(
          data: (clients) => DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: AppStyles.inputDecoration(),
            items: clients
                .map<DropdownMenuItem<String>>((ClientSimpleModel c) =>
                    DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.fullName,
                            style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedClientId = v);
                _updateClientData(v);
              }
            },
            validator: (v) => v == null ? 'Requerido' : null,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, __) => Text('Error: $e'),
        ),
      ],
    );
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
            decoration: AppStyles.inputDecoration()),
      ],
    );
  }

  Widget _buildDateSelector(
      String label, DateTime? date, Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
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
                Text(
                    date != null
                        ? DateFormat('MM/dd/yyyy').format(date)
                        : 'Seleccionar',
                    style: const TextStyle(fontSize: 14)),
                const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    if (_selectedItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay items seleccionados',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                horizontalMargin: 12,
                columnSpacing: 10,
                columns: const [
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Precio', textAlign: TextAlign.right)),
                  DataColumn(label: Text('Cant.', textAlign: TextAlign.right)),
                  DataColumn(label: Text('Tax %', textAlign: TextAlign.right)),
                  DataColumn(label: Text('Total', textAlign: TextAlign.right)),
                  DataColumn(label: Text('')),
                ],
                rows: _selectedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
                  final price = (item['sale_price'] as num?)?.toDouble() ?? 0.0;
                  final tax = (item['tax'] as num?)?.toDouble() ?? 0.0;
                  final total = qty * price * (1 + tax / 100);

                  return DataRow(cells: [
                    DataCell(SizedBox(
                      width: constraints.maxWidth * 0.3,
                      child: Text(item['PoleBarns']['name'] ?? 'Item',
                          overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: price.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() =>
                            item['sale_price'] = double.tryParse(v) ?? 0.0),
                        decoration: const InputDecoration(
                            border: InputBorder.none, isDense: true),
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 50,
                      child: TextFormField(
                        initialValue: qty.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(
                            () => item['qty'] = double.tryParse(v) ?? 1.0),
                        decoration: const InputDecoration(
                            border: InputBorder.none, isDense: true),
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 50,
                      child: TextFormField(
                        initialValue: tax.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(
                            () => item['tax'] = double.tryParse(v) ?? 0.0),
                        decoration: const InputDecoration(
                            border: InputBorder.none, isDense: true),
                      ),
                    )),
                    DataCell(Text(NumberFormat.simpleCurrency().format(total))),
                    DataCell(IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () =>
                          setState(() => _selectedItems.removeAt(index)),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogSelectionDialog extends StatefulWidget {
  final List<CatalogItemModel> items;
  final Function(List<CatalogItemModel>) onSelected;

  const _CatalogSelectionDialog(
      {required this.items, required this.onSelected});

  @override
  State<_CatalogSelectionDialog> createState() =>
      _CatalogSelectionDialogState();
}

class _CatalogSelectionDialogState extends State<_CatalogSelectionDialog> {
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Items del Catálogo'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _selectedIds.contains(item.id);
            return CheckboxListTile(
              title: Text(item.name),
              subtitle:
                  Text(NumberFormat.simpleCurrency().format(item.salePrice)),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(item.id);
                  } else {
                    _selectedIds.remove(item.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final selected =
                widget.items.where((i) => _selectedIds.contains(i.id)).toList();
            widget.onSelected(selected);
            Navigator.pop(context);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
