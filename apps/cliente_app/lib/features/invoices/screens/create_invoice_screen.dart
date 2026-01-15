import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../../project_tracking/providers/project_providers.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../utils/invoice_pdf_generator.dart';
import '../../clients/repositories/client_repository.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const CreateInvoiceScreen({super.key, this.projectId});

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
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onProjectSelected(widget.projectId);
      });
    }
  }

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
    if (!_formKey.currentState!.validate() || _selectedProjectId == null) {
      return;
    }

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

      final newId = await ref
          .read(invoiceServiceProvider)
          .createInvoice(newInvoice, productsToInsert);

      // Attempt to send by email automatically
      _sendInvoiceEmail(newId);

      ref.invalidate(invoicesListProvider);
      if (_selectedProjectId != null) {
        ref.invalidate(invoiceByProjectProvider(_selectedProjectId!));
      }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Factura',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información General',
                            style: AppStyles.dialogTitleStyle),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildProjectDropdown(projectsAsync),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildClientDropdown(clientsAsync),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                            'Dirección de Facturación', _addressController,
                            required: true),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                  'Fecha de Factura',
                                  _selectedDate,
                                  (d) => setState(() => _selectedDate = d)),
                            ),
                            const SizedBox(width: 24),
                            const Spacer(), // Empty space for balance
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                            'Comentario (Opcional)', _commentController,
                            maxLines: 3),
                        const SizedBox(height: 32),
                        if (_projectPoleBarns.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                          const Text(
                            'Estructuras del Proyecto (Se incluirán en la factura):',
                            style: AppStyles.labelStyle,
                          ),
                          const SizedBox(height: 16),
                          ..._projectPoleBarns.map((pb) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(pb['PoleBarns']['name'] ?? 'Pole Barn',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                        NumberFormat.simpleCurrency()
                                            .format(pb['sale_price']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppStyles.primaryOrange)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 32),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveInvoice,
                            style: AppStyles.primaryButtonStyle,
                            child: const Text('Guardar Factura'),
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

  Widget _buildProjectDropdown(AsyncValue projectsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proyecto', style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        projectsAsync.when(
          data: (projects) => DropdownButtonFormField<String>(
            value: _selectedProjectId,
            decoration: AppStyles.inputDecoration(),
            items: projects
                .map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.address ?? p.id,
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: _onProjectSelected,
            validator: (v) => v == null ? 'Seleccione un proyecto' : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, __) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
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
                .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.fullName,
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedClientId = v),
            validator: (v) => v == null ? 'Seleccione un cliente' : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, __) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Requerido' : null
              : null,
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
                lastDate: DateTime(2100));
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
}
