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
      backgroundColor: AppStyles.stoneWhite,
      appBar: AppBar(
        title: const Text(
          'Detalles del Cliente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        backgroundColor: AppStyles.primaryForest,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                backgroundColor: AppStyles.secondaryEarth,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Crear Invoice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _confirmDelete,
            tooltip: 'Eliminar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Accent Bar
            Container(
              height: 4,
              color: AppStyles.secondaryEarth,
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, client),
                    const SizedBox(height: 32),
                    _buildInvoicesTable(client.id),
                  ],
                ),
              ),
            ),
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
          final isMobile = constraints.maxWidth < 650;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.paleSage),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.primaryForest.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppStyles.secondaryEarth,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Historial de Invoices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.primaryForest,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMobile)
                  _buildMobileInvoicesList(invoices, currency, dateFormat)
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor:
                            WidgetStateProperty.all(AppStyles.paleSage),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppStyles.primaryForest,
                          letterSpacing: 0.5,
                          fontFamily: 'Manrope',
                        ),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 24,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('REF')),
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
                                      color: AppStyles.primaryForest,
                                      fontWeight: FontWeight.w600))),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                      invoice.projectName ??
                                          invoice.address ??
                                          'Sin Proyecto',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppStyles.primaryForest,
                                          fontSize: 13)),
                                ),
                              ),
                              DataCell(Text(dateFormat.format(invoice.date))),
                              DataCell(
                                  Text(currency.format(invoice.totalVenta))),
                              DataCell(Text(
                                  currency.format(invoice.totalPagado),
                                  style: const TextStyle(
                                      color: Color(0xFF166534)))),
                              DataCell(Text(currency.format(invoice.saldo),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: invoice.saldo > 0
                                          ? const Color(0xFF991B1B)
                                          : AppStyles.primaryForest))),
                              DataCell(_buildInvoiceStatusBadge(invoice)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMobileInvoicesList(List<InvoiceModel> invoices,
      NumberFormat currency, DateFormat dateFormat) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return InkWell(
          onTap: () => _navigateToInvoiceDetail(inv.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppStyles.stoneWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.paleSage),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${inv.id}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppStyles.primaryForest)),
                    _buildInvoiceStatusBadge(inv),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(dateFormat.format(inv.date),
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo:',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(currency.format(inv.saldo),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: inv.saldo > 0
                                ? const Color(0xFF991B1B)
                                : AppStyles.primaryForest)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    if (status == 'Pagado') color = const Color(0xFF166534);
    if (status == 'Parcial') color = AppStyles.secondaryEarth;
    if (status == 'Pendiente') color = const Color(0xFF991B1B);
    if (status == 'Cancelado') color = const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ClientModel client) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.paleSage),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primaryForest.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Design Element
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.architecture,
                  size: 200, color: AppStyles.primaryForest),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(client, radius: 60),
                      const SizedBox(height: 24),
                      _buildMainInfo(client, isCentered: true),
                      const SizedBox(height: 32),
                      const Divider(color: AppStyles.paleSage),
                      const SizedBox(height: 32),
                      _buildContactInfo(client),
                      const SizedBox(height: 32),
                      _buildLocationNotes(client),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(client, radius: 80),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 3,
                        child: _buildMainInfo(client),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 3,
                        child: _buildContactInfo(client),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: _buildLocationNotes(client),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ClientModel client, {required double radius}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppStyles.secondaryEarth, width: 2),
      ),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppStyles.paleSage,
        backgroundImage:
            client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
        child: client.photoUrl == null
            ? Text(
                client.firstName.isNotEmpty
                    ? client.firstName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                    color: AppStyles.primaryForest),
              )
            : null,
      ),
    );
  }

  Widget _buildMainInfo(ClientModel client, {bool isCentered = false}) {
    return Column(
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          client.nombre.toUpperCase(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
            color: AppStyles.primaryForest,
            letterSpacing: -0.5,
          ),
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        _buildStatusBadge(true),
        const SizedBox(height: 16),
        Text(
          'CLIENTE DESDE: ${DateFormat('MMMM yyyy').format(DateTime.now())}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(ClientModel client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('INFORMACIÓN DE CONTACTO'),
        const SizedBox(height: 20),
        _buildInfoRow(Icons.phone_android, client.telefono ?? 'No disponible'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.alternate_email, client.email ?? 'No disponible'),
      ],
    );
  }

  Widget _buildLocationNotes(ClientModel client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (client.direccion != null && client.direccion!.isNotEmpty) ...[
          _buildLabel('UBICACIÓN PRINCIPAL'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.location_on_outlined, client.direccion!),
          const SizedBox(height: 24),
        ],
        if (client.notas != null && client.notas!.isNotEmpty) ...[
          _buildLabel('NOTAS INTERNAS'),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.description_outlined, client.notas!),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppStyles.secondaryEarth,
        fontWeight: FontWeight.w900,
        fontSize: 10,
        fontFamily: 'Manrope',
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppStyles.primaryForest.withValues(alpha: 0.4)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppStyles.primaryForest,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF166534).withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: isActive
                ? const Color(0xFF166534).withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          color: isActive ? const Color(0xFF166534) : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'Manrope',
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: AppStyles.stoneWhite,
        title: const Text(
          'Eliminar Cliente',
          style: TextStyle(
            color: AppStyles.primaryForest,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        content: const Text(
          '¿Seguro que deseas eliminar este cliente? Esta acción no se puede deshacer.',
          style: TextStyle(fontFamily: 'Manrope', color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontSize: 12,
              ),
            ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppStyles.stoneWhite,
      appBar: AppBar(
        title: Text(
          isNew ? 'Nuevo Cliente' : 'Editar Cliente',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        backgroundColor: AppStyles.primaryForest,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppStyles.secondaryEarth, width: 2),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isUploading
                                      ? null
                                      : _pickAndUploadImage,
                                  borderRadius: BorderRadius.circular(60),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppStyles.paleSage,
                                    backgroundImage: _photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : null,
                                    child: _photoUrl == null && !_isUploading
                                        ? const Icon(Icons.person,
                                            size: 60,
                                            color: AppStyles.primaryForest)
                                        : _isUploading
                                            ? const CircularProgressIndicator()
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: AppStyles.secondaryEarth,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _isUploading
                                      ? null
                                      : _pickAndUploadImage,
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
                          icon: const Icon(Icons.upload, color: AppStyles.secondaryEarth),
                          label: const Text(
                            'Cambiar Foto',
                            style: TextStyle(
                              color: AppStyles.secondaryEarth,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text('INFORMACIÓN DEL CLIENTE',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                          color: AppStyles.primaryForest)),
                  const SizedBox(height: 32),
                  isMobile
                      ? Column(
                          children: [
                            _buildTextField('Nombre *', _nombreController,
                                required: true),
                            const SizedBox(height: 24),
                            _buildTextField('Apellido *', _apellidoController,
                                required: true),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  'Nombre *', _nombreController,
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
                  isMobile
                      ? Column(
                          children: [
                            _buildTextField('Teléfono', _phoneController,
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 24),
                            _buildTextField('Email', _emailController,
                                keyboardType: TextInputType.emailAddress),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    'Teléfono', _phoneController,
                                    keyboardType: TextInputType.phone)),
                            const SizedBox(width: 24),
                            Expanded(
                                child: _buildTextField(
                                    'Email', _emailController,
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
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppStyles.secondaryEarth,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            fontFamily: 'Manrope',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Manrope',
              color: AppStyles.primaryForest),
          keyboardType: keyboardType,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Requerido' : null
              : null,
          decoration: AppStyles.inputDecoration().copyWith(
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppStyles.paleSage),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppStyles.secondaryEarth),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )
      ],
    );
  }
}
