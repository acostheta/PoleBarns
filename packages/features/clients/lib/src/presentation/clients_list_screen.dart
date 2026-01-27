import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/clients_repository.dart';
import 'package:design_system/design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

// Provider to fetch profiles for audit log resolution
final profilesProvider = FutureProvider<Map<String, Map<String, dynamic>>>((
  ref,
) async {
  final data =
      await Supabase.instance.client.from('profiles').select('id, name, email');
  return {for (var user in data) user['id'] as String: user};
});

class ClientsListScreen extends ConsumerStatefulWidget {
  final void Function(String clientId, Map<String, dynamic> client)?
      onCreateEstimate;
  const ClientsListScreen({super.key, this.onCreateEstimate});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  String? _selectedClientId;
  bool _isCreatingNew = false;
  String _searchQuery = '';

  // Filters
  bool _showFilters = false;
  bool? _filterIsActive;

  void _startCreatingNew() {
    setState(() {
      _selectedClientId = null;
      _isCreatingNew = true;
    });
  }

  void _selectClient(String id) {
    setState(() {
      _selectedClientId = id;
      _isCreatingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);

    return clientsAsync.when(
      data: (clients) {
        final filteredClients = clients.where((c) {
          final firstName = (c['first_name'] as String? ?? '').toLowerCase();
          final lastName = (c['last_name'] as String? ?? '').toLowerCase();
          final email = (c['email'] as String? ?? '').toLowerCase();
          final phone = (c['phone'] as String? ?? '').toLowerCase();
          final mobile = (c['mobile'] as String? ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();

          final matchesSearch = firstName.contains(q) ||
              lastName.contains(q) ||
              email.contains(q) ||
              phone.contains(q) ||
              mobile.contains(q);

          bool matchesStatus = true;
          if (_filterIsActive != null) {
            final isActive = c['is_active'] as bool? ?? false;
            matchesStatus = isActive == _filterIsActive;
          }

          return matchesSearch && matchesStatus;
        }).toList();

        final selectedClient = (_selectedClientId != null)
            ? clients.firstWhere(
                (c) => c['id'] == _selectedClientId,
                orElse: () => <String, dynamic>{},
              )
            : null;

        final effectiveClient =
            (selectedClient != null && selectedClient.isNotEmpty)
                ? selectedClient
                : null;

        return Container(
          color: AppColors.backgroundLight,
          child: Column(
            children: [
              // Header Area
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestión de Clientes',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(allClientsProvider),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.stone300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Split Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar (List)
                    Container(
                      width: 350,
                      margin: const EdgeInsets.only(left: 24, bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.stone200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // List Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Client List',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    Text(
                                      '${filteredClients.length} Encontrados',
                                      style: const TextStyle(
                                        color: AppColors.stone500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _startCreatingNew,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Agregar Cliente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.stone100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: AppColors.stone400,
                                        ),
                                        hintText: 'Buscar clientes...',
                                        hintStyle: TextStyle(
                                          color: AppColors.stone400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showFilters = !_showFilters;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: _showFilters
                                        ? AppColors.primary
                                        : AppColors.stone500,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _showFilters
                                        ? AppColors.primaryLight
                                            .withValues(alpha: 0.2)
                                        : AppColors.stone100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Filters Panel
                          if (_showFilters)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.stone50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.stone200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterDropdown(
                                    label: 'Estado',
                                    value: _filterIsActive?.toString(),
                                    itemsMaps: [
                                      {'value': 'true', 'label': 'Activo'},
                                      {'value': 'false', 'label': 'Inactivo'},
                                    ],
                                    onChanged: (val) => setState(
                                      () => _filterIsActive = val == 'true',
                                    ),
                                    onClear: () => setState(
                                      () => _filterIsActive = null,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),
                          // User List Items
                          Expanded(
                            child: filteredClients.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No se encontraron clientes',
                                      style: TextStyle(
                                        color: AppColors.stone400,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: filteredClients.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final client = filteredClients[index];
                                      final isSelected =
                                          client['id'] == _selectedClientId &&
                                              !_isCreatingNew;
                                      return _buildClientListItem(
                                        context,
                                        client,
                                        isSelected,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Detail Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: (_isCreatingNew || effectiveClient != null)
                            ? ClientDetailPanel(
                                key: ValueKey(
                                  _isCreatingNew
                                      ? 'new'
                                      : effectiveClient!['id'],
                                ),
                                client: effectiveClient,
                                isCreating: _isCreatingNew,
                                onSaved: () {
                                  setState(() {
                                    _isCreatingNew = false;
                                    _selectedClientId = null;
                                  });
                                  ref.invalidate(allClientsProvider);
                                },
                                onCreateEstimate: widget.onCreateEstimate,
                              )
                            : _buildEmptyState(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.stone500,
              ),
            ),
            if (value != null)
              InkWell(
                onTap: onClear,
                child: const Text(
                  'Limpiar',
                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 36,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.stone300),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            items: itemsMaps!
                .map(
                  (m) => DropdownMenuItem(
                    value: m['value'],
                    child: Text(m['label']!),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildClientListItem(
    BuildContext context,
    Map<String, dynamic> client,
    bool isSelected,
  ) {
    final isActive = client['is_active'] as bool? ?? false;
    final firstName = client['first_name'] as String? ?? 'Desconocido';
    final lastName = client['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectClient(client['id']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGreenLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.accentGreen, width: 4),
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Desconocido',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accentGreenDark
                            : AppColors.textLight,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client['email'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.accentGreen
                            : AppColors.stone500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : AppColors.stone300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.stone50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stone100),
            ),
            child: const Icon(
              Icons.business,
              size: 64,
              color: AppColors.stone300,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ningún cliente seleccionado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seleccione un cliente de la lista o agregue uno nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.stone500),
          ),
        ],
      ),
    );
  }
}

class ClientDetailPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic>? client;
  final bool isCreating;
  final VoidCallback onSaved;
  final void Function(String clientId, Map<String, dynamic> client)?
      onCreateEstimate;

  const ClientDetailPanel({
    super.key,
    this.client,
    required this.isCreating,
    required this.onSaved,
    this.onCreateEstimate,
  });

  @override
  ConsumerState<ClientDetailPanel> createState() => _ClientDetailPanelState();
}

class _ClientDetailPanelState extends ConsumerState<ClientDetailPanel> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;
  late TextEditingController _mobileController;
  late TextEditingController _noteController;

  bool _isActive = true;
  Timer? _debounce;

  // Validators
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
  static final _numericRegex = RegExp(r'^[0-9]+$');
  // Allow + only at the start
  static final _phoneRegex = RegExp(r'^\+?[0-9]+$');
  String? _photoUrl;
  bool _isUploading = false;

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

      if (widget.isCreating) {
        setState(() {
          _photoUrl = publicUrl;
          _isUploading = false;
        });
      } else {
        await ref.read(clientsRepositoryProvider).updateClient(
          widget.client!['id'],
          {'photo_url': publicUrl},
        );
        setState(() {
          _photoUrl = publicUrl;
          _isUploading = false;
        });
        ref.invalidate(allClientsProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada correctamente')),
        );
      }
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
  void initState() {
    super.initState();
    final c = widget.client;
    _firstNameController = TextEditingController(text: c?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: c?['last_name'] ?? '');
    _emailController = TextEditingController(text: c?['email'] ?? '');
    _phoneController = TextEditingController(text: c?['phone'] ?? '');
    _addressController = TextEditingController(text: c?['address'] ?? '');
    _addressLine2Controller = TextEditingController(
      text: c?['address_line_2'] ?? '',
    );
    _cityController = TextEditingController(text: c?['city'] ?? '');
    _stateController = TextEditingController(text: c?['state'] ?? '');
    _zipCodeController = TextEditingController(text: c?['zip_code'] ?? '');
    _countryController = TextEditingController(text: c?['country'] ?? '');
    _mobileController = TextEditingController(text: c?['mobile'] ?? '');
    _noteController = TextEditingController(text: c?['note'] ?? '');

    _isActive = c?['is_active'] as bool? ?? true;
    _photoUrl = c?['photo_url'] as String?;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _mobileController.dispose();
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFieldChanged(String field, dynamic value) {
    if (widget.isCreating) return;

    // Validate before auto-saving strictly?
    // Auto-save typically saves partial valid data, but for better UX, maybe we check validity
    if (!_formKey.currentState!.validate()) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await ref.read(clientsRepositoryProvider).updateClient(
        widget.client!['id'],
        {field: value},
      );
      ref.invalidate(allClientsProvider);
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'address_line_2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip_code': _zipCodeController.text,
        'country': _countryController.text,
        'mobile': _mobileController.text,
        'note': _noteController.text,
        'is_active': _isActive,
        'photo_url': _photoUrl,
      };

      await ref.read(clientsRepositoryProvider).createClient(data);
      ref.invalidate(allClientsProvider);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final fullName = '$firstName $lastName'.trim();
    final displayTitle = fullName.isNotEmpty ? fullName : 'Nuevo Cliente';

    // Audit Info Resolution
    // Audit Info Resolution
    final createdBy = widget.client?['created_by'] as String?;
    final createdAt = widget.client?['created_at'] as String?;
    final updatedBy = widget.client?['updated_by'] as String?;
    final updatedAt = widget.client?['updated_at'] as String?;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.stone200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.stone200,
                                shape: BoxShape.circle,
                                image: _photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: _photoUrl == null && !_isUploading
                                  ? Text(
                                      widget.isCreating
                                          ? '+'
                                          : (firstName.isNotEmpty
                                              ? firstName[0].toUpperCase()
                                              : 'C'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.stone500,
                                      ),
                                    )
                                  : _isUploading
                                      ? const CircularProgressIndicator()
                                      : null,
                            ),
                          ),
                          if (!_isUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                        child: const Text(
                          'Cambiar Foto',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? AppColors.accentGreenLight
                                    : AppColors.stone100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isActive ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: _isActive
                                      ? AppColors.accentGreenDark
                                      : AppColors.stone500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isCreating && widget.onCreateEstimate != null)
                    ElevatedButton.icon(
                      onPressed: () => widget.onCreateEstimate!(
                        widget.client!['id'],
                        widget.client!,
                      ),
                      icon: const Icon(Icons.description_outlined, size: 20),
                      label: const Text('Crear Estimado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.stone200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.person, 'Información Personal'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'Nombre *',
                          onChanged: (val) {
                            if (!widget.isCreating)
                              _onFieldChanged('first_name', val);
                            setState(() {});
                          },
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Apellido *',
                          onChanged: (val) {
                            if (!widget.isCreating)
                              _onFieldChanged('last_name', val);
                            setState(() {});
                          },
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    Icons.contact_mail,
                    'Información de Contacto',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Correo *',
                          onChanged: (val) => _onFieldChanged('email', val),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Requerido';
                            if (!_emailRegex.hasMatch(val))
                              return 'Correo inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Teléfono *',
                          onChanged: (val) => _onFieldChanged('phone', val),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Requerido';
                            if (!_phoneRegex.hasMatch(val))
                              return 'Formato inválido (ej. +123...)';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _mobileController,
                          label: 'Móvil *',
                          onChanged: (val) => _onFieldChanged('mobile', val),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Requerido';
                            if (!_phoneRegex.hasMatch(val))
                              return 'Formato inválido (ej. +123...)';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.location_on, 'Dirección'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Dirección Línea 1 *',
                    onChanged: (val) => _onFieldChanged('address', val),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressLine2Controller,
                    label: 'Dirección Línea 2 (Opcional)',
                    onChanged: (val) => _onFieldChanged('address_line_2', val),
                    // No validator
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'Ciudad *',
                          onChanged: (val) => _onFieldChanged('city', val),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _stateController,
                          label: 'Estado/Provincia *',
                          onChanged: (val) => _onFieldChanged('state', val),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _zipCodeController,
                          label: 'Código Postal *',
                          onChanged: (val) => _onFieldChanged('zip_code', val),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Requerido';
                            if (!_numericRegex.hasMatch(val))
                              return 'Solo números';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _countryController,
                    label: 'País *',
                    onChanged: (val) => _onFieldChanged('country', val),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(Icons.note, 'Notas'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _noteController,
                    label: 'Nota (Opcional)',
                    maxLines: 3,
                    onChanged: (val) => _onFieldChanged('note', val),
                    // No validator
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    Icons.settings,
                    'Información del Sistema',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Estado',
                    value: _isActive ? 'true' : 'false',
                    itemsMaps: [
                      {'value': 'true', 'label': 'Activo'},
                      {'value': 'false', 'label': 'Inactivo'},
                    ],
                    onChanged: (val) {
                      final boolVal = val == 'true';
                      setState(() => _isActive = boolVal);
                      _onFieldChanged('is_active', boolVal);
                    },
                  ),
                  if (!widget.isCreating) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.stone200),
                    const SizedBox(height: 8),
                    const Text(
                      'Registro de Auditoría',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.stone500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Creado: ${createdAt != null ? DateTime.parse(createdAt).toLocal().toString().split('.')[0] : 'Desconocido'}',
                      style: const TextStyle(
                        color: AppColors.stone500,
                        fontSize: 13,
                      ),
                    ),
                    profilesAsync.when(
                      data: (profiles) {
                        final creator =
                            createdBy != null ? profiles[createdBy] : null;
                        final creatorName = creator != null
                            ? '${creator['name']} (${creator['email']})'
                            : (createdBy ?? 'Desconocido');
                        return Text(
                          'Por: $creatorName',
                          style: const TextStyle(
                            color: AppColors.stone800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Por: Cargando...',
                        style: TextStyle(
                          color: AppColors.stone400,
                          fontSize: 13,
                        ),
                      ),
                      error: (e, s) => Text(
                        'Por: Error al cargar usuario ($createdBy)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Última Actualización: ${updatedAt != null ? DateTime.parse(updatedAt).toLocal().toString().split('.')[0] : 'Desconocido'}',
                      style: const TextStyle(
                        color: AppColors.stone500,
                        fontSize: 13,
                      ),
                    ),
                    profilesAsync.when(
                      data: (profiles) {
                        final updater =
                            updatedBy != null ? profiles[updatedBy] : null;
                        final updaterName = updater != null
                            ? '${updater['name']} (${updater['email']})'
                            : (updatedBy ?? 'Desconocido');
                        return Text(
                          'Por: $updaterName',
                          style: const TextStyle(
                            color: AppColors.stone800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Por: Cargando...',
                        style: TextStyle(
                          color: AppColors.stone400,
                          fontSize: 13,
                        ),
                      ),
                      error: (e, s) => Text(
                        'Por: Error al cargar usuario ($updatedBy)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (widget.isCreating) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Crear Cliente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? hint,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.stone100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.stone100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.stone300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: itemsMaps!
                  .map(
                    (m) => DropdownMenuItem(
                      value: m['value'],
                      child: Text(m['label']!),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.textLight, fontSize: 14),
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
