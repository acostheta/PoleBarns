import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';

class ProjectCreateDialog extends ConsumerStatefulWidget {
  const ProjectCreateDialog({super.key});

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
      ventaTotal: 0,
      costosTotales: 0,
      profit: 0,
      comments: _commentsController.text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(projectRepositoryProvider).createProject(newProject);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            data: (clients) => DropdownButtonFormField<String>(
                              value: _selectedClientId,
                              items: clients
                                  .map<DropdownMenuItem<String>>((c) =>
                                      DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(c.fullName,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedClientId = val),
                              decoration: AppStyles.inputDecoration(),
                              validator: (v) => v == null ? 'Requerido' : null,
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
                                data: (profiles) =>
                                    DropdownButtonFormField<String>(
                                  value: _selectedResponsable,
                                  items: profiles
                                      .map<DropdownMenuItem<String>>((p) =>
                                          DropdownMenuItem<String>(
                                              value: p['full_name'] as String,
                                              child: Text(
                                                  p['full_name'] as String,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (val) => setState(
                                      () => _selectedResponsable = val),
                                  decoration: AppStyles.inputDecoration(),
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
                                            style:
                                                const TextStyle(fontSize: 14))))
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
                          InkWell(
                            onTap: () => _showMultiSelectGroup(context, ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedGroupUsers.isEmpty
                                          ? 'Seleccione usuarios'
                                          : _selectedGroupUsers.join(', '),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedGroupUsers.isEmpty
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.group_add,
                                      size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
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

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
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

  void _showMultiSelectGroup(BuildContext context, WidgetRef ref) {
    ref.read(profilesProvider).whenData((profiles) {
      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar Grupo'),
              content: SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: profiles.length,
                  itemBuilder: (ctx, i) {
                    final p = profiles[i];
                    final name = p['full_name'] as String;
                    final isSelected = _selectedGroupUsers.contains(name);
                    return CheckboxListTile(
                      title: Text(name),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedGroupUsers.add(name);
                          } else {
                            _selectedGroupUsers.remove(name);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          });
        },
      );
    });
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
