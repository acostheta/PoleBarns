import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../project_tracking/providers/project_providers.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedProjectId;
  String? _selectedClientId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _projectPoleBarns = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onProjectSelected(String? projectId) async {
    if (projectId == null) return;

    setState(() {
      _selectedProjectId = projectId;
      _isLoading = true;
    });

    try {
      final projects = ref.read(projectListProvider).asData?.value ?? [];
      final selectedProject = projects.firstWhere((p) => p.id == projectId);

      setState(() {
        _selectedClientId = selectedProject.refCliente;
        _addressController.text = selectedProject.address ?? '';
      });

      // Fetch Pole Barns for this project
      final pb =
          await ref.read(invoiceServiceProvider).getProjectPoleBarns(projectId);
      setState(() {
        _projectPoleBarns = pb;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del proyecto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate() || _selectedProjectId == null)
      return;

    setState(() => _isLoading = true);

    try {
      final totalVenta = _projectPoleBarns.fold<double>(
          0, (sum, item) => sum + (item['sale_price'] as num).toDouble());

      final newInvoice = InvoiceModel(
        id: 0,
        idProyecto: _selectedProjectId,
        idCliente: _selectedClientId,
        address: _addressController.text,
        date: _selectedDate,
        totalVenta: totalVenta,
        comentario: _commentController.text,
        createdAt: DateTime.now(),
      );

      // Prepare products to insert
      final productsToInsert = _projectPoleBarns.map((pb) {
        return {
          'IdProyecto': _selectedProjectId,
          'IdPoleBarns': pb['pole_barn_id'],
          'Estatus': 'Pendiente',
          'Cantidad': 1.0,
          'Precio por unidad': pb['sale_price'],
          'Tax': 0.0,
        };
      }).toList();

      await ref
          .read(invoiceServiceProvider)
          .createInvoice(newInvoice, productsToInsert);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura creada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear factura: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Selection
                    projectsAsync.when(
                      data: (projects) => DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        decoration:
                            const InputDecoration(labelText: 'Proyecto'),
                        items: projects
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.address ?? p.id),
                                ))
                            .toList(),
                        onChanged: _onProjectSelected,
                        validator: (v) =>
                            v == null ? 'Seleccione un proyecto' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, __) => Text('Error cargando proyectos: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Client (Pre-filled or selectable)
                    clientsAsync.when(
                      data: (clients) => DropdownButtonFormField<String>(
                        value: _selectedClientId,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.fullName),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClientId = v),
                        validator: (v) =>
                            v == null ? 'Seleccione un cliente' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, __) => Text('Error cargando clientes: $e'),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Dirección de Facturación'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      title: const Text('Fecha'),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                          labelText: 'Comentario (Opcional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    if (_projectPoleBarns.isNotEmpty) ...[
                      const Text(
                          'Estructuras del Proyecto (Se incluirán en la factura):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._projectPoleBarns.map((pb) => ListTile(
                            title: Text(pb['PoleBarns']['name'] ?? 'Pole Barn'),
                            trailing: Text(NumberFormat.simpleCurrency()
                                .format(pb['sale_price'])),
                            dense: true,
                          )),
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Guardar Factura'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
