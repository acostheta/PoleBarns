import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';
import 'package:users/users.dart';

class ProjectCreateDialog extends ConsumerStatefulWidget {
  final String? initialClientId;
  const ProjectCreateDialog({super.key, this.initialClientId});

  @override
  ConsumerState<ProjectCreateDialog> createState() =>
      _ProjectCreateDialogState();
}

class _ProjectCreateDialogState extends ConsumerState<ProjectCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  final _addressController = TextEditingController();
  String? _selectedClientId;
  String? _selectedResponsable;
  List<String> _selectedGroupUsers = [];
  String _selectedStatus = 'En Proceso';

  final List<String> _statusOptions = ['Pendiente', 'En Proceso', 'Terminado'];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  final _commentsController = TextEditingController();

  // Pole Barn Selection
  final List<Map<String, dynamic>> _selectedStructures = [];
  double get _totalStructuresPrice => _selectedStructures.fold(
      0, (sum, item) => sum + (item['precio_venta'] as num).toDouble());

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.initialClientId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')));
      return;
    }

    // Create Model
    final newProject = ProjectModel(
      id: '',
      refCliente: _selectedClientId!,
      responsable: _selectedResponsable ?? 'N/A',
      estatus: _selectedStatus,
      grupoAsignado: _selectedGroupUsers.join(', '),
      address: _addressController.text,
      fechaInicio: _startDate,
      fechaFinalizacion: _endDate,
      ventaTotal: _totalStructuresPrice,
      costosTotales: 0,
      profit: 0,
      comments: _commentsController.text,
      createdAt: DateTime.now(),
    );

    try {
      final repo = ref.read(projectRepositoryProvider);
      final createdProject = await repo.createProject(newProject);

      // Add Pole Barns
      for (final struct in _selectedStructures) {
        await repo.addProjectPoleBarn(
          createdProject.id,
          struct['id'] as int,
          (struct['precio_venta'] as num).toDouble(),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear el proyecto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nuevo Proyecto',
                          style: AppStyles.dialogTitleStyle),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  _buildTextField(
                      'Nombre del Proyecto / Dirección', _addressController,
                      required: true),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cliente', style: AppStyles.labelStyle),
                            const SizedBox(height: 8),
                            clientsAsync.when(
                              data: (clients) =>
                                  DropdownButtonFormField<String>(
                                value: _selectedClientId,
                                items: clients
                                    .map<DropdownMenuItem<String>>((c) =>
                                        DropdownMenuItem<String>(
                                            value: c.id,
                                            child: Text(c.fullName,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedClientId = val),
                                decoration: AppStyles.inputDecoration(),
                                validator: (v) =>
                                    v == null ? 'Requerido' : null,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Error: $e',
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Responsable',
                                style: AppStyles.labelStyle),
                            const SizedBox(height: 8),
                            ref.watch(profilesProvider).when(
                                  data: (profiles) {
                                    // Map current name to ID if exists
                                    String? selectedId;
                                    try {
                                      selectedId = profiles.firstWhere((p) =>
                                          p['full_name'] ==
                                          _selectedResponsable)['id'];
                                    } catch (_) {}

                                    return DropdownButtonFormField<String>(
                                      value: selectedId,
                                      items: profiles
                                          .map<DropdownMenuItem<String>>((p) =>
                                              DropdownMenuItem<String>(
                                                  value: p['id'] as String,
                                                  child: Text(
                                                      (p['full_name']
                                                              as String?) ??
                                                          'Unknown',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      overflow: TextOverflow
                                                          .ellipsis)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final name = profiles.firstWhere(
                                                  (p) => p['id'] == val)[
                                              'full_name'] as String?;
                                          setState(() =>
                                              _selectedResponsable = name);
                                        }
                                      },
                                      decoration: AppStyles.inputDecoration(),
                                      isExpanded: true,
                                      icon:
                                          const Icon(Icons.keyboard_arrow_down),
                                    );
                                  },
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text('Error: $e',
                                      style:
                                          const TextStyle(color: Colors.red)),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estatus', style: AppStyles.labelStyle),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              items: _statusOptions
                                  .map<DropdownMenuItem<String>>((s) =>
                                      DropdownMenuItem<String>(
                                          value: s,
                                          child: Text(s,
                                              style: const TextStyle(
                                                  fontSize: 14))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedStatus = val);
                                }
                              },
                              decoration: AppStyles.inputDecoration(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Grupo', style: AppStyles.labelStyle),
                            const SizedBox(height: 8),
                            ref.watch(workerGroupsProvider).when(
                                  data: (groups) {
                                    final usersAsync =
                                        ref.watch(allUsersProvider);
                                    return DropdownButtonFormField<String>(
                                      value: groups.any((g) =>
                                              g['name'] ==
                                              _selectedGroupUsers.join(', '))
                                          ? _selectedGroupUsers.join(', ')
                                          : null,
                                      items: groups
                                          .map<DropdownMenuItem<String>>((g) {
                                        final supervisorId =
                                            g['supervisor_id'] as String?;
                                        final supervisorName = usersAsync.when(
                                          data: (users) => users.firstWhere(
                                            (u) => u['id'] == supervisorId,
                                            orElse: () => {},
                                          )['name'] as String?,
                                          loading: () => '...',
                                          error: (_, __) => null,
                                        );

                                        final displayName = supervisorName !=
                                                null
                                            ? '${g['name']} (Responsable: $supervisorName)'
                                            : (g['name'] as String);

                                        return DropdownMenuItem<String>(
                                          value: g['name'] as String,
                                          child: Text(displayName,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedGroupUsers =
                                              val != null ? [val] : [];
                                        });
                                      },
                                      decoration: AppStyles.inputDecoration(),
                                      isExpanded: true,
                                      icon:
                                          const Icon(Icons.keyboard_arrow_down),
                                      hint: const Text('Seleccionar Grupo',
                                          style: TextStyle(fontSize: 14)),
                                    );
                                  },
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text('Error: $e',
                                      style:
                                          const TextStyle(color: Colors.red)),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                          child: _buildDateField('Fecha Inicio', _startDate,
                              (d) => setState(() => _startDate = d))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDateField('Fecha Fin', _endDate,
                              (d) => setState(() => _endDate = d))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Comentarios', _commentsController,
                      maxLines: 3),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estructuras (Catálogo)',
                          style: AppStyles.labelStyle),
                      TextButton.icon(
                        onPressed: () => _showAddStructureDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedStructures.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Ninguna estructura seleccionada',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic)),
                    )
                  else
                    Column(
                      children: _selectedStructures.map((struct) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        struct['name'] as String? ??
                                            'Sin nombre',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                        NumberFormat.simpleCurrency()
                                            .format(struct['precio_venta']),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedStructures.remove(struct);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (_selectedStructures.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Total Venta Estimada: ',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                              NumberFormat.simpleCurrency()
                                  .format(_totalStructuresPrice),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: AppStyles.primaryButtonStyle,
                      child: const Text('Crear Proyecto'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
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

  void _showAddStructureDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final catalogAsync = ref.watch(poleBarnsCatalogProvider);
          return AlertDialog(
            title: const Text('Añadir Estructura'),
            content: SizedBox(
              width: double.maxFinite,
              child: catalogAsync.when(
                data: (items) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['name'] as String? ?? 'Sin nombre'),
                      subtitle: Text(NumberFormat.simpleCurrency()
                          .format(item['precio_venta'])),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        setState(() {
                          _selectedStructures.add(item);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
