import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'package:users/users.dart';

class ProjectFormSection extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectFormSection({super.key, required this.project});

  @override
  ConsumerState<ProjectFormSection> createState() => _ProjectFormSectionState();
}

class _ProjectFormSectionState extends ConsumerState<ProjectFormSection> {
  bool _isEditing = false;

  // Controllers / State
  late TextEditingController _responsableController;
  late TextEditingController _grupoController;
  late TextEditingController _nameController;
  late TextEditingController _direccionController;
  late TextEditingController _commentsController;

  String? _selectedClientId;
  String? _selectedResponsable;
  List<String> _selectedGroupUsers = [];
  late String _selectedStatus;

  final List<String> _statusOptions = ['Pendiente', 'En Proceso', 'Terminado'];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _responsableController =
        TextEditingController(text: widget.project.responsable);
    _grupoController =
        TextEditingController(text: widget.project.grupoAsignado);
    _nameController = TextEditingController(text: widget.project.address);
    _direccionController =
        TextEditingController(text: widget.project.direccion);
    _commentsController = TextEditingController(text: widget.project.comments);

    _selectedClientId = widget.project.refCliente;
    _selectedResponsable = widget.project.responsable;
    _selectedGroupUsers = (widget.project.grupoAsignado ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _selectedStatus = widget.project.estatus ?? 'En Proceso';
    // Fallback if status not in options, usually 'En Proceso' or add it.
    if (!_statusOptions.contains(_selectedStatus) &&
        _selectedStatus.isNotEmpty) {
      _statusOptions.add(_selectedStatus);
    }

    _startDate = widget.project.fechaInicio;
    _endDate = widget.project.fechaFinalizacion;
  }

  @override
  void didUpdateWidget(covariant ProjectFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id ||
        oldWidget.project != widget.project) {
      // Only re-init if ID changed or project data updated externally and we are not editing
      if (!_isEditing) {
        _initControllers();
      }
    }
  }

  @override
  void dispose() {
    _responsableController.dispose();
    _grupoController.dispose();
    _nameController.dispose();
    _direccionController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.project.copyWith(
      refCliente: _selectedClientId ?? '',
      responsable: _selectedResponsable,
      estatus: _selectedStatus,
      grupoAsignado: _selectedGroupUsers.join(', '),
      address: _nameController.text,
      direccion: _direccionController.text,
      comments: _commentsController.text,
      fechaInicio: _startDate,
      fechaFinalizacion: _endDate,
    );

    try {
      await ref.read(projectRepositoryProvider).updateProject(updated);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              const Text('Detalles del Proyecto',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827))),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit,
                      size: 16, color: Color(0xFFD97706)),
                  label: const Text('Editar Detalles',
                      style: TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 24),
          if (!_isEditing) ...[
            Wrap(
              spacing: 32,
              runSpacing: 24,
              children: [
                SizedBox(
                    width: 300,
                    child:
                        _buildReadFieldSimple('NOMBRE', _nameController.text)),
                SizedBox(
                    width: 300, child: _buildClientReadField(clientsAsync)),
                SizedBox(
                    width: 300,
                    child: _buildReadStatusPill('ESTATUS', _selectedStatus)),
                SizedBox(
                    width: 300,
                    child: _buildReadFieldSimple(
                        'GRUPO ASIGNADO', _selectedGroupUsers.join(', '))),
                SizedBox(
                  width: 300,
                  child: Consumer(builder: (context, ref, child) {
                    final profilesAsync = ref.watch(profilesProvider);
                    final profile = profilesAsync.valueOrNull?.firstWhere(
                      (p) => p['full_name'] == _selectedResponsable,
                      orElse: () => {},
                    );
                    return _buildReadFieldWithAvatar(
                        'RESPONSABLE',
                        _selectedResponsable ?? '-',
                        _getInitials(_selectedResponsable ?? '-'),
                        imageUrl: profile?['picture']);
                  }),
                ),
                SizedBox(
                    width: 300,
                    child: _buildReadFieldWithIcon('FECHA DE INICIO',
                        _startDate, Icons.calendar_today_outlined)),
                SizedBox(
                    width: 300,
                    child: _buildReadFieldWithIcon('FECHA DE FIN ESTIMADA',
                        _endDate, Icons.event_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            _buildReadFieldWithIcon(
                'DIRECCIÓN', null, Icons.location_on_outlined,
                customText: _direccionController.text),
            const SizedBox(height: 24),
            _buildReadFieldSimple('COMENTARIOS', _commentsController.text),
          ] else ...[
            // EDIT MODE
            _buildField('Nombre', _nameController),
            const SizedBox(height: 16),
            _buildField('Dirección', _direccionController),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(width: 350, child: _buildClientDropdown(clientsAsync)),
                SizedBox(width: 350, child: _buildGroupSelection()),
                SizedBox(width: 350, child: _buildStatusDropdown()),
                SizedBox(width: 350, child: _buildResponsableDropdown()),
                SizedBox(
                    width: 350,
                    child: _buildDateField('Fecha de Inicio', _startDate,
                        (d) => setState(() => _startDate = d))),
                SizedBox(
                    width: 350,
                    child: _buildDateField('Fecha de Fin', _endDate,
                        (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Comentarios', _commentsController, maxLines: 5),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      _initControllers();
                      setState(() => _isEditing = false);
                    },
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[800]),
                    child: const Text('Cancelar')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1))
      ],
    );
  }

  // --- Widgets ---

  Widget _buildClientReadField(
      AsyncValue<List<ClientSimpleModel>> clientsAsync) {
    return clientsAsync.when(
      data: (clients) {
        final client = clients.firstWhere((c) => c.id == _selectedClientId,
            orElse: () =>
                ClientSimpleModel(id: '', firstName: 'Unknown', lastName: ''));
        final name =
            client.id.isEmpty ? (_selectedClientId ?? '-') : client.fullName;
        return _buildReadFieldWithAvatar('CLIENTE', name, _getInitials(name),
            imageUrl: client.photoUrl);
      },
      loading: () => _buildReadFieldSimple('CLIENTE', 'Loading...'),
      error: (_, __) => _buildReadFieldSimple('CLIENTE', 'Error'),
    );
  }

  Widget _buildClientDropdown(
      AsyncValue<List<ClientSimpleModel>> clientsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: clientsAsync.when(
            data: (clients) => DropdownButtonFormField<String>(
              value: _selectedClientId,
              items: clients
                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<
                          String>(
                      value: c.id,
                      child: Text(c.fullName, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedClientId = val),
              decoration: _inputDecoration(),
              isExpanded: true,
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsableDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Responsable',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: ref.watch(profilesProvider).when(
                data: (profiles) {
                  // Find ID for current name
                  String? selectedId;
                  try {
                    selectedId = profiles.firstWhere(
                        (p) => p['full_name'] == _selectedResponsable)['id'];
                  } catch (_) {}

                  return DropdownButtonFormField<String>(
                    value: selectedId,
                    items: profiles
                        .map<DropdownMenuItem<String>>((p) =>
                            DropdownMenuItem<String>(
                                value: p['id'] as String,
                                child: Text(
                                    (p['full_name'] as String?) ?? 'N/A',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final name = profiles.firstWhere(
                            (p) => p['id'] == val)['full_name'] as String?;
                        setState(() => _selectedResponsable = name);
                      }
                    },
                    decoration: _inputDecoration(),
                    isExpanded: true,
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
        ),
      ],
    );
  }

  Widget _buildGroupSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grupo Asignado',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        ref.watch(workerGroupsProvider).when(
              data: (groups) {
                final usersAsync = ref.watch(allUsersProvider);
                return DropdownButtonFormField<String>(
                  value: groups.any(
                          (g) => g['name'] == _selectedGroupUsers.join(', '))
                      ? _selectedGroupUsers.join(', ')
                      : null,
                  items: groups.map<DropdownMenuItem<String>>((g) {
                    final supervisorId = g['supervisor_id'] as String?;
                    final supervisorName = usersAsync.when(
                      data: (users) => users.firstWhere(
                        (u) => u['id'] == supervisorId,
                        orElse: () => {},
                      )['name'] as String?,
                      loading: () => '...',
                      error: (_, __) => null,
                    );

                    final displayName = supervisorName != null
                        ? '${g['name']} (Responsable: $supervisorName)'
                        : (g['name'] as String);

                    return DropdownMenuItem<String>(
                      value: g['name'] as String,
                      child: Text(displayName,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      // Find the supervisor name for this group
                      final group = groups.firstWhere((g) => g['name'] == val);
                      final supervisorId = group['supervisor_id'] as String?;
                      final users = usersAsync.valueOrNull ?? [];
                      final supervisor = users.firstWhere(
                        (u) => u['id'] == supervisorId,
                        orElse: () => {},
                      );
                      final supervisorName = supervisor['name'] as String?;

                      setState(() {
                        _selectedGroupUsers = [val];
                        if (supervisorName != null) {
                          _selectedResponsable = supervisorName;
                        }
                      });
                    } else {
                      setState(() {
                        _selectedGroupUsers = [];
                      });
                    }
                  },
                  decoration: _inputDecoration(),
                  isExpanded: true,
                  hint: const Text('Seleccionar Grupo',
                      style: TextStyle(fontSize: 14)),
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estado del Proyecto',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: _statusOptions
                .map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD97706))),
    );
  }

  // --- Reuse helpers from original (simplified) ---

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildReadFieldWithAvatar(String label, String value, String initials,
      {String? imageUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Text(initials,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
                child: Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                    overflow: TextOverflow.ellipsis)),
          ],
        )
      ],
    );
  }

  Widget _buildReadStatusPill(String label, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16)),
          child: Text(status.isEmpty ? 'Unknown' : status,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E))),
        ),
      ],
    );
  }

  Widget _buildReadFieldSimple(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildReadFieldWithIcon(String label, DateTime? date, IconData icon,
      {String? customText}) {
    final text = customText ??
        (date != null ? DateFormat('dd MMM, yyyy').format(date) : '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ],
        )
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration()),
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime) onChanged) {
    final display = date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontSize: 13)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(display, style: const TextStyle(fontSize: 14)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        )
      ],
    );
  }
}
