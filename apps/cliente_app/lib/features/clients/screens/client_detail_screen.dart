import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../invoices/models/invoice_models.dart';
import '../../invoices/screens/invoice_detail_screen.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const ClientDetailScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  // Form Key & Controllers for Edit Mode
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  ClientModel? _client;
  String? _photoUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientId == 'new') {
      _isEditing = true;
    } else if (widget.clientId != null) {
      _loadClient();
    }
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);
    try {
      final client =
          await ref.read(clientRepositoryProvider).getClient(widget.clientId!);
      if (client != null) {
        // Populate form controllers
        _nombreController.text = client.firstName;
        _apellidoController.text = client.lastName;
        _phoneController.text = client.telefono ?? '';
        _emailController.text = client.email ?? '';
        _addressController.text = client.direccion ?? '';
        _notesController.text = client.notas ?? '';

        setState(() {
          _client = client;
          _photoUrl = client.photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final client = ClientModel(
        id: widget.clientId == 'new' ? '' : widget.clientId!,
        firstName: _nombreController.text,
        lastName: _apellidoController.text,
        telefono: _phoneController.text,
        email: _emailController.text,
        direccion: _addressController.text,
        notas: _notesController.text,
        photoUrl: _photoUrl,
      );

      final repo = ref.read(clientRepositoryProvider);
      if (widget.clientId == 'new') {
        await repo.createClient(client);
        if (mounted) {
          context.pop(); // Go back after creation
        }
      } else {
        await repo.updateClient(widget.clientId!, client);
        await _loadClient(); // Reload to update View mode
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cliente guardado')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final fileName = 'clients/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      setState(() {
        _photoUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isEditing) {
      return _buildEditMode();
    } else {
      return _buildViewMode();
    }
  }

  // --- View Mode ---

  Widget _buildViewMode() {
    final client = _client;
    if (client == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Consistent background
      appBar: AppBar(
        title: const Text('Cliente',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateInvoiceScreen(clientId: client.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Crear Invoice',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(client),
            const SizedBox(height: 24),
            _buildInvoicesTable(client.id),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTable(String clientId) {
    final invoicesAsync = ref.watch(invoicesByClientStreamProvider(clientId));
    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat('MM/dd/yyyy');

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) return const SizedBox();

        return LayoutBuilder(builder: (context, constraints) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Invoices Recientes',
                      style: AppStyles.dialogTitleStyle),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 24,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('ID (#)')),
                          DataColumn(label: Text('PROYECTO')),
                          DataColumn(label: Text('FECHA')),
                          DataColumn(label: Text('TOTAL'), numeric: true),
                          DataColumn(label: Text('PAGADO'), numeric: true),
                          DataColumn(label: Text('SALDO'), numeric: true),
                          DataColumn(label: Text('ESTADO')),
                        ],
                        rows: invoices.map((invoice) {
                          return DataRow(
                            onSelectChanged: (_) =>
                                _navigateToInvoiceDetail(invoice.id),
                            cells: [
                              DataCell(Text('#${invoice.id}',
                                  style: const TextStyle(
                                      color: Color(0xFF4B5563)))),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                      invoice.projectName ??
                                          invoice.address ??
                                          'Sin Proyecto',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 12)),
                                ),
                              ),
                              DataCell(Text(dateFormat.format(invoice.date))),
                              DataCell(
                                  Text(currency.format(invoice.totalVenta))),
                              DataCell(Text(
                                  currency.format(invoice.totalPagado),
                                  style: const TextStyle(
                                      color: Color(0xFF059669)))),
                              DataCell(Text(currency.format(invoice.saldo),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: invoice.saldo > 0
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF111827)))),
                              DataCell(_buildInvoiceStatusBadge(invoice)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _navigateToInvoiceDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoiceId: id),
      ),
    );
  }

  Widget _buildInvoiceStatusBadge(InvoiceModel invoice) {
    String status = 'Pendiente';
    if (invoice.status.toLowerCase() == 'cancelada' ||
        invoice.status.toLowerCase() == 'cancelado') {
      status = 'Cancelado';
    } else if (invoice.saldo <= 0) {
      status = 'Pagado';
    } else if (invoice.totalPagado > 0) {
      status = 'Parcial';
    }

    Color color = Colors.grey;
    if (status == 'Pagado') color = const Color(0xFF059669);
    if (status == 'Parcial') color = const Color(0xFFD97706);
    if (status == 'Pendiente') color = const Color(0xFFDC2626);
    if (status == 'Cancelado') color = const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ClientModel client) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFF3F4F6),
            backgroundImage:
                client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
            child: client.photoUrl == null
                ? Text(
                    client.firstName.isNotEmpty
                        ? client.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9CA3AF)),
                  )
                : null,
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.nombre,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusBadge(true), // Assuming active for now
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Column 2: Contact Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONTACTO',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(client.telefono ?? 'S/N',
                        style: const TextStyle(
                            color: Color(0xFF4B5563), fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(client.email ?? 'S/N',
                        style: const TextStyle(
                            color: Color(0xFF4B5563), fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Column 3: Address and Notes
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.direccion != null &&
                    client.direccion!.isNotEmpty) ...[
                  const Text('DIRECCIÓN',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(client.direccion!,
                            style: const TextStyle(
                                color: Color(0xFF4B5563), fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (client.notas != null && client.notas!.isNotEmpty) ...[
                  const Text('NOTAS',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(client.notas!,
                            style: const TextStyle(
                                color: Color(0xFF4B5563), fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text(
            '¿Seguro que deseas eliminar este cliente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _client != null) {
      await ref.read(clientRepositoryProvider).deleteClient(_client!.id);
      if (mounted) context.pop();
    }
  }

  // --- Edit Mode (Form) ---

  Widget _buildEditMode() {
    final isNew = widget.clientId == 'new';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Nuevo Cliente' : 'Editar Cliente',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isNew) {
              context.pop();
            } else {
              setState(() => _isEditing = false);
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    _isUploading ? null : _pickAndUploadImage,
                                borderRadius: BorderRadius.circular(60),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  backgroundImage: _photoUrl != null
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                                  child: _photoUrl == null && !_isUploading
                                      ? const Icon(Icons.person,
                                          size: 60, color: Color(0xFF9CA3AF))
                                      : _isUploading
                                          ? const CircularProgressIndicator()
                                          : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: const Color(0xFFD97706),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap:
                                      _isUploading ? null : _pickAndUploadImage,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.camera_alt,
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                          icon: const Icon(Icons.upload),
                          label: const Text('Cambiar Foto'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text('Información del Cliente',
                      style: AppStyles.dialogTitleStyle),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Nombre *', _nombreController,
                            required: true),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                            'Apellido *', _apellidoController,
                            required: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField('Teléfono', _phoneController,
                              keyboardType: TextInputType.phone)),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildTextField('Email', _emailController,
                              keyboardType: TextInputType.emailAddress)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Dirección', _addressController),
                  const SizedBox(height: 24),
                  _buildTextField('Notas', _notesController, maxLines: 4),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: AppStyles.primaryButtonStyle,
                      child: Text(isNew ? 'Crear Cliente' : 'Guardar Cambios'),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, TextInputType? keyboardType, int maxLines = 1}) {
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
          decoration: AppStyles.inputDecoration(),
        )
      ],
    );
  }
}
